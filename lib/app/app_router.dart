import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../activities/common/activity_screen.dart';
import '../map/home_screen.dart';
import '../map/step_screen.dart';
import '../map/sticker_album.dart';
import '../profiles/adults_screen.dart';

GoRouter createAppRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/adults', builder: (context, state) => const AdultsScreen()),
    GoRoute(path: '/stickers', builder: (context, state) => const StickerAlbum()),
    GoRoute(
      path: '/step/:stepId',
      builder: (context, state) =>
          StepScreen(key: ValueKey(state.uri.path), stepId: state.pathParameters['stepId']!),
    ),
    GoRoute(
      path: '/play/:stepId/:activityId',
      builder: (context, state) => ActivityScreen(
        key: ValueKey(state.uri.path),
        stepId: state.pathParameters['stepId']!,
        activityId: state.pathParameters['activityId']!,
      ),
    ),
  ],
);
