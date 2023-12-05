import 'dart:io';

import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// External Packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:l10n_esperanto/l10n_esperanto.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/community/bloc/anonymous_subscriptions_bloc.dart';
import 'package:thunder/community/bloc/community_bloc.dart';
import 'package:thunder/core/enums/local_settings.dart';
import 'package:thunder/core/singletons/lemmy_client.dart';
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/instance/bloc/instance_bloc.dart';

// Internal Packages
import 'package:thunder/routes.dart';
import 'package:thunder/core/enums/theme_type.dart';
import 'package:thunder/core/singletons/database.dart';
import 'package:thunder/core/theme/bloc/theme_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';
import 'package:thunder/thunder/thunder.dart';
import 'package:thunder/utils/global_context.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //Setting SystemUIMode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load up sqlite database
  await DB.instance.database;

  // Register dart_ping on iOS
  if (!kIsWeb && Platform.isIOS) {
    DartPingIOS.register();
  }

  final String initialInstance = (await UserPreferences.instance).sharedPreferences.getString(LocalSettings.currentAnonymousInstance.name) ?? 'lemmy.ml';
  LemmyClient.instance.changeBaseUrl(initialInstance);

  runApp(const ThunderApp());
}

class ThunderApp extends StatelessWidget {
  const ThunderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeBloc(),
        ),
        BlocProvider(
          create: (context) => AuthBloc(),
        ),
        BlocProvider(
          create: (context) => AccountBloc(),
        ),
        BlocProvider(
          create: (context) => DeepLinksCubit(),
        ),
        BlocProvider(
          create: (context) => ThunderBloc(),
        ),
        BlocProvider(
          create: (context) => AnonymousSubscriptionsBloc(),
        ),
        BlocProvider(
          create: (context) => CommunityBloc(lemmyClient: LemmyClient.instance),
        ),
        BlocProvider(
          create: (context) => InstanceBloc(lemmyClient: LemmyClient.instance),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          final ThunderBloc thunderBloc = context.watch<ThunderBloc>();

          if (state.status == ThemeStatus.initial) {
            context.read<ThemeBloc>().add(ThemeChangeEvent());
          }
          return DynamicColorBuilder(
            builder: (lightColorScheme, darkColorScheme) {
              ThemeData theme = FlexThemeData.light(useMaterial3: true, scheme: FlexScheme.values.byName(state.selectedTheme.name));
              ThemeData darkTheme = FlexThemeData.dark(useMaterial3: true, scheme: FlexScheme.values.byName(state.selectedTheme.name), darkIsTrueBlack: state.themeType == ThemeType.pureBlack);

              // Enable Material You theme
              if (state.useMaterialYouTheme == true) {
                theme = ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                );

                darkTheme = FlexThemeData.dark(
                  useMaterial3: true,
                  colorScheme: darkColorScheme,
                  darkIsTrueBlack: state.themeType == ThemeType.pureBlack,
                );
              }

              // Set the page transitions
              const PageTransitionsTheme pageTransitionsTheme = PageTransitionsTheme(builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              });

              theme = theme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              );
              darkTheme = darkTheme.copyWith(
                pageTransitionsTheme: pageTransitionsTheme,
              );

              // Set navigation bar color on Android to be transparent
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.black.withOpacity(0.0001),
                ),
              );

              Locale? locale = AppLocalizations.supportedLocales.where((Locale locale) => locale.languageCode == thunderBloc.state.appLanguageCode).firstOrNull;

              return OverlaySupport.global(
                child: MaterialApp.router(
                  title: 'Thunder',
                  locale: locale,
                  localizationsDelegates: const [
                    ...AppLocalizations.localizationsDelegates,
                    MaterialLocalizationsEo.delegate,
                    CupertinoLocalizationsEo.delegate,
                  ],
                  supportedLocales: const [
                    ...AppLocalizations.supportedLocales,
                    Locale('eo'), // Additional locale which is not officially supported: Esperanto
                  ],
                  routerConfig: router,
                  themeMode: state.themeType == ThemeType.system ? ThemeMode.system : (state.themeType == ThemeType.light ? ThemeMode.light : ThemeMode.dark),
                  theme: theme,
                  darkTheme: darkTheme,
                  debugShowCheckedModeBanner: false,
                  scaffoldMessengerKey: GlobalContext.scaffoldMessengerKey,
                  scrollBehavior: (state.reduceAnimations && Platform.isAndroid) ? const ScrollBehavior().copyWith(overscroll: false) : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
