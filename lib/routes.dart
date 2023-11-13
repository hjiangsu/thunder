import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:thunder/account/bloc/account_bloc.dart';
import 'package:thunder/core/auth/bloc/auth_bloc.dart';

import 'package:thunder/settings/pages/about_settings_page.dart';
import 'package:thunder/settings/pages/accessibility_settings_page.dart';
import 'package:thunder/settings/pages/appearance_settings_page.dart';
import 'package:thunder/settings/pages/debug_settings_page.dart';
import 'package:thunder/settings/pages/fab_settings_page.dart';
import 'package:thunder/settings/pages/general_settings_page.dart';
import 'package:thunder/settings/pages/gesture_settings_page.dart';
import 'package:thunder/settings/pages/post_settings_page.dart';
import 'package:thunder/settings/pages/theme_settings_page.dart';
import 'package:thunder/settings/settings.dart';
import 'package:thunder/thunder/bloc/thunder_bloc.dart';
import 'package:thunder/thunder/thunder.dart';

final GoRouter router = GoRouter(
  debugLogDiagnostics: true,
  routes: <GoRoute>[
    GoRoute(
      name: 'home',
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const Thunder(),
      routes: const <GoRoute>[],
    ),
    GoRoute(
      name: 'settings',
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) => SettingsPage(),
      routes: <GoRoute>[
        GoRoute(
          name: 'general',
          path: 'general',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const GeneralSettingsPage(),
            );
          },
        ),
        GoRoute(
          name: 'appearance',
          path: 'appearance',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const AppearanceSettingsPage(),
            );
          },
          routes: [
            GoRoute(
              name: 'themes',
              path: 'themes',
              builder: (context, state) {
                return BlocProvider.value(
                  value: state.extra! as ThunderBloc,
                  child: const ThemeSettingsPage(),
                );
              },
            ),
            GoRoute(
              name: 'posts',
              path: 'posts',
              builder: (context, state) {
                return BlocProvider.value(
                  value: state.extra! as ThunderBloc,
                  child: const PostAppearanceSettingsPage(),
                );
              },
            ),
          ],
        ),
        GoRoute(
          name: 'gestures',
          path: 'gestures',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const GestureSettingsPage(),
            );
          },
        ),
        GoRoute(
          name: 'fab',
          path: 'fab',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const FabSettingsPage(),
            );
          },
        ),
        GoRoute(
          name: 'accessibility',
          path: 'accessibility',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const AccessibilitySettingsPage(),
            );
          },
        ),
        GoRoute(
          name: 'about',
          path: 'about',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: (state.extra! as List)[0] as ThunderBloc),
                BlocProvider.value(value: (state.extra! as List)[1] as AccountBloc),
                BlocProvider.value(value: (state.extra! as List)[2] as AuthBloc),
              ],
              child: const AboutSettingsPage(),
            );
          },
        ),
        GoRoute(
          name: 'debug',
          path: 'debug',
          builder: (context, state) {
            return BlocProvider.value(
              value: state.extra! as ThunderBloc,
              child: const DebugSettingsPage(),
            );
          },
        ),
      ],
    ),
  ],
);
