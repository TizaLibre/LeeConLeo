import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import 'about_view.dart';
import 'adults_guide.dart';
import 'parental_gate.dart';
import 'profile_manager.dart';

class AdultsScreen extends StatefulWidget {
  const AdultsScreen({super.key});

  static const backKey = ValueKey('adults-back');
  static const tabs = ['Perfiles', 'Guía', 'Acerca de'];

  @override
  State<AdultsScreen> createState() => _AdultsScreenState();
}

class _AdultsScreenState extends State<AdultsScreen> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: AdultsScreen.tabs.length,
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        appBar: AppBar(
          backgroundColor: AppTheme.cream,
          leading: IconButton(
            key: AdultsScreen.backKey,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/'),
          ),
          bottom: _isOpen
              ? TabBar(
                  tabs: [
                    for (final tab in AdultsScreen.tabs) Tab(key: ValueKey('tab-$tab'), text: tab),
                  ],
                )
              : null,
        ),
        body: SafeArea(
          child: _isOpen
              ? const TabBarView(children: [ProfileManager(), AdultsGuide(), AboutView()])
              : ParentalGate(onPassed: () => setState(() => _isOpen = true)),
        ),
      ),
    );
  }
}
