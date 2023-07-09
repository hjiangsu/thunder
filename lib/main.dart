import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// External Packages
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

// Internal Packages
import 'package:thunder/core/singletons/preferences.dart';
import 'package:thunder/routes.dart';
import 'package:thunder/core/singletons/database.dart';
import 'package:thunder/core/theme/bloc/theme_bloc.dart';

// Ignore specific exceptions to send to Sentry
FutureOr<SentryEvent?> beforeSend(SentryEvent event, {Hint? hint}) async {
  if (event.exceptions != null &&
      event.exceptions!.isNotEmpty &&
      event.exceptions!.first.value != null &&
      event.exceptions!.first.value!.contains('The request returned an invalid status code of 400.')) {
    return null;
  }

  return event;
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  //Setting SystmeUIMode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load up environment variables
  await dotenv.load(fileName: ".env");

  // Load up sqlite database
  await DB.instance.database;

  // Load up SharedPreferences to check if Sentry error tracking is enabled - it is disabled by default
  await UserPreferences.instance.refetchPreferences();

  SharedPreferences prefs = UserPreferences.instance.sharedPreferences;
  bool enableSentryErrorTracking = prefs.getBool('setting_error_tracking_enable_sentry') ?? false;
  String? sentryDSN = enableSentryErrorTracking ? dotenv.env['SENTRY_DSN'] : null;

  if (sentryDSN != null) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kDebugMode ? '' : sentryDSN;
        options.debug = kDebugMode;
        options.tracesSampleRate = kDebugMode ? 1.0 : 0.1;
        options.beforeSend = beforeSend;
      },
      appRunner: () => runApp(const ThunderApp()),
    );
  } else {
    runApp(const ThunderApp());
  }
}

class ThunderApp extends StatelessWidget {
  const ThunderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeBloc(),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          if (state.status == ThemeStatus.initial) {
            context.read<ThemeBloc>().add(ThemeChangeEvent());
          }
          return DynamicColorBuilder(
            builder: (lightColorScheme, darkColorScheme) {
              ThemeData theme = FlexThemeData.light(useMaterial3: true, scheme: FlexScheme.deepBlue);
              ThemeData darkTheme = FlexThemeData.dark(useMaterial3: true, scheme: FlexScheme.deepBlue, darkIsTrueBlack: state.useBlackTheme);

              // Enable Material You theme
              if (state.useMaterialYouTheme == true) {
                theme = ThemeData(
                  colorScheme: lightColorScheme,
                  useMaterial3: true,
                );

                darkTheme = FlexThemeData.dark(
                  useMaterial3: true,
                  colorScheme: darkColorScheme,
                  darkIsTrueBlack: state.useBlackTheme,
                );
              }

              // Set navigation bar color on Android to be transparent
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  systemNavigationBarColor: Colors.black.withOpacity(0.0001),
                ),
              );

              return OverlaySupport.global(
                child: MaterialApp.router(
                  title: 'Thunder',
                  routerConfig: router,
                  themeMode: state.useSystemTheme ? ThemeMode.system : (state.useDarkTheme ? ThemeMode.dark : ThemeMode.light),
                  theme: theme,
                  darkTheme: darkTheme,
                  debugShowCheckedModeBanner: false,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
