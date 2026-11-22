import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/audio/audio_providers.dart';
import 'app_router.dart';
import 'app_theme.dart';

class LeeConLeoApp extends ConsumerStatefulWidget {
  const LeeConLeoApp({super.key});

  @override
  ConsumerState<LeeConLeoApp> createState() => _LeeConLeoAppState();
}

class _LeeConLeoAppState extends ConsumerState<LeeConLeoApp> {
  final GoRouter _router = createAppRouter();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => ref.read(pausablePlayerProvider).pause(),
      onShow: () => ref.read(pausablePlayerProvider).resume(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Lee con Leo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => ref.read(promptPlayerProvider).resumeAfterUserGesture(),
        child: child,
      ),
    );
  }
}
