import 'package:bloc/bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';
import 'package:lemmy_api_client/v3.dart';
import 'package:collection/collection.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:thunder/utils/error_messages.dart';
import 'package:thunder/account/models/account.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';

part 'auth_event.dart';
part 'auth_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<RemoveAccount>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading, isLoggedIn: false));

      await Account.deleteAccount(event.accountId);

      await Future.delayed(const Duration(seconds: 1), () {
        return emit(state.copyWith(status: AuthStatus.success, isLoggedIn: false));
      });
    });

    /// This event occurs whenever you switch to a different authenticated account
    on<SwitchAccount>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading, isLoggedIn: false));

      Account? account = await Account.fetchAccount(event.accountId);
      if (account == null) return emit(state.copyWith(status: AuthStatus.success, account: null, isLoggedIn: false));

      // Set this account as the active account
      SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      prefs.setString('active_profile_id', event.accountId);

      // Check to see the instance settings (for checking if downvotes are enabled)
      LemmyClient.instance.changeBaseUrl(account.instance!.replaceAll('https://', ''));
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      GetSiteResponse getSiteResponse = await lemmy.run(GetSite(auth: account.jwt));
      bool downvotesEnabled = getSiteResponse.siteView.localSite.enableDownvotes;

      return emit(state.copyWith(
        status: AuthStatus.success,
        account: account,
        isLoggedIn: true,
        downvotesEnabled: downvotesEnabled,
        getSiteResponse: getSiteResponse,
        reload: event.reload,
      ));
    });

    // This event should be triggered during the start of the app, or when there is a change in the active account
    on<CheckAuth>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.loading, account: null, isLoggedIn: false));

      // Check to see what the current active account/profile is
      // The profile will match an account in the database (through the account's id)
      SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      String? activeProfileId = prefs.getString('active_profile_id');

      // If there is an existing jwt, remove it from the prefs
      String? jwt = prefs.getString('jwt');

      if (jwt != null) {
        prefs.remove('jwt');
        return emit(state.copyWith(status: AuthStatus.failure, account: null, isLoggedIn: false, errorMessage: 'You have been logged out. Please log in again!'));
      }

      if (activeProfileId == null) {
        return emit(state.copyWith(status: AuthStatus.success, account: null, isLoggedIn: false));
      }

      List<Account> accounts = await Account.accounts();

      if (accounts.isEmpty) {
        return emit(state.copyWith(status: AuthStatus.success, account: null, isLoggedIn: false));
      }

      Account? activeAccount = accounts.firstWhereOrNull((Account account) => account.id == activeProfileId);

      if (activeAccount == null) {
        return emit(state.copyWith(status: AuthStatus.success, account: null, isLoggedIn: false));
      }

      if (activeAccount.username != null && activeAccount.jwt != null && activeAccount.instance != null) {
        // Set lemmy client to use the instance
        LemmyClient.instance.changeBaseUrl(activeAccount.instance!.replaceAll('https://', ''));

        // Check to see the instance settings (for checking if downvotes are enabled)
        LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

        bool downvotesEnabled = true;
        GetSiteResponse? getSiteResponse;
        try {
          getSiteResponse = await lemmy.run(GetSite(auth: activeAccount.jwt)).timeout(const Duration(seconds: 15));

          downvotesEnabled = getSiteResponse.siteView.localSite.enableDownvotes;
        } catch (e) {
          return emit(state.copyWith(status: AuthStatus.failureCheckingInstance, errorMessage: getExceptionErrorMessage(e)));
        }

        return emit(state.copyWith(status: AuthStatus.success, account: activeAccount, isLoggedIn: true, downvotesEnabled: downvotesEnabled, getSiteResponse: getSiteResponse));
      }
    }, transformer: throttleDroppable(throttleDuration));

    /// This event should be triggered when the user logs in with a username/password
    on<LoginAttempt>((event, emit) async {
      LemmyClient lemmyClient = LemmyClient.instance;
      String originalBaseUrl = lemmyClient.lemmyApiV3.host;

      try {
        emit(state.copyWith(status: AuthStatus.loading, account: null, isLoggedIn: false));

        String instance = event.instance;
        if (instance.startsWith('https://')) instance = instance.replaceAll('https://', '');

        lemmyClient.changeBaseUrl(instance);
        LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

        LoginResponse loginResponse = await lemmy.run(Login(
          usernameOrEmail: event.username,
          password: event.password,
          totp2faToken: event.totp,
        ));

        if (loginResponse.jwt == null) {
          return emit(state.copyWith(status: AuthStatus.failure, account: null, isLoggedIn: false));
        }

        GetSiteResponse getSiteResponse = await lemmy.run(GetSite(auth: loginResponse.jwt));

        // Create a new account in the database
        Uuid uuid = const Uuid();
        String accountId = uuid.v4().replaceAll('-', '').substring(0, 13);

        Account account = Account(
          id: accountId,
          username: getSiteResponse.myUser?.localUserView.person.name,
          jwt: loginResponse.jwt,
          instance: instance,
          userId: getSiteResponse.myUser?.localUserView.person.id,
        );

        await Account.insertAccount(account);

        // Set this account as the active account
        SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
        prefs.setString('active_profile_id', accountId);

        bool downvotesEnabled = getSiteResponse.siteView.localSite.enableDownvotes;

        return emit(state.copyWith(status: AuthStatus.success, account: account, isLoggedIn: true, downvotesEnabled: downvotesEnabled, getSiteResponse: getSiteResponse));
      } on LemmyApiException catch (e) {
        return emit(state.copyWith(status: AuthStatus.failure, account: null, isLoggedIn: false, errorMessage: e.toString()));
      } catch (e) {
        try {
          // Restore the original baseUrl
          lemmyClient.changeBaseUrl(originalBaseUrl);
        } catch (e, s) {
          return emit(state.copyWith(status: AuthStatus.failure, account: null, isLoggedIn: false, errorMessage: s.toString()));
        }
        return emit(state.copyWith(status: AuthStatus.failure, account: null, isLoggedIn: false, errorMessage: e.toString()));
      }
    });

    /// When we log out of all accounts, clear the instance information
    on<LogOutOfAllAccounts>((event, emit) async {
      emit(state.copyWith(status: AuthStatus.initial));
      final SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      prefs.setString('active_profile_id', '');
      return emit(state.copyWith(status: AuthStatus.success, isLoggedIn: false, getSiteResponse: null));
    });

    /// When the given instance changes, re-fetch the instance information and preferences.
    on<InstanceChanged>((event, emit) async {
      // Copy everything from the state as is during loading
      emit(state.copyWith(status: AuthStatus.loading, isLoggedIn: state.isLoggedIn, account: state.account));

      // When the instance changes, update the fullSiteView
      LemmyClient.instance.changeBaseUrl(event.instance.replaceAll('https://', ''));
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      // Check to see if there is an active, non-anonymous account
      SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      String? activeProfileId = prefs.getString('active_profile_id');
      Account? account = (activeProfileId != null) ? await Account.fetchAccount(activeProfileId) : null;

      GetSiteResponse getSiteResponse = await lemmy.run(GetSite(auth: account?.jwt));
      bool downvotesEnabled = getSiteResponse.siteView.localSite.enableDownvotes;

      return emit(state.copyWith(status: AuthStatus.success, account: account, isLoggedIn: activeProfileId?.isNotEmpty == true, downvotesEnabled: downvotesEnabled, getSiteResponse: getSiteResponse));
    });

    /// When any account setting synced with Lemmy is updated, re-fetch the instance information and preferences.
    on<LemmyAccountSettingUpdated>((event, emit) async {
      LemmyApiV3 lemmy = LemmyClient.instance.lemmyApiV3;

      // Check to see if there is an active, non-anonymous account
      SharedPreferences prefs = (await UserPreferences.instance).sharedPreferences;
      String? activeProfileId = prefs.getString('active_profile_id');
      Account? account = (activeProfileId != null) ? await Account.fetchAccount(activeProfileId) : null;

      GetSiteResponse getSiteResponse = await lemmy.run(GetSite(auth: account?.jwt));
      return emit(state.copyWith(
        status: AuthStatus.success,
        account: account,
        isLoggedIn: activeProfileId?.isNotEmpty == true,
        getSiteResponse: getSiteResponse,
        reload: false,
      ));
    });
  }
}
