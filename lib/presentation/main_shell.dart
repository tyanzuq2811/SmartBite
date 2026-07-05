import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../core/localization/app_localizations.dart';
import 'home/home_screen.dart';
import 'input_hub/input_hub_screen.dart';
import 'plan/plan_screen.dart';
import 'settings/settings_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  int _prevIndex = 0;
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(key: _homeKey),
      const InputHubScreen(),
      const PlanScreen(),
      const SettingsScreen(),
    ];
  }

  void onTabSelected(int index) {
    setState(() {
      _prevIndex = _currentIndex;
      _currentIndex = index;
    });
    if (index == 0) {
      _homeKey.currentState?.loadSavedRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 350),
        reverse: _currentIndex < _prevIndex,
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: onTabSelected,
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: isDark ? const Color(0x3D34D399) : const Color(0x1F10B981),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.translate('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.document_scanner_outlined),
            selectedIcon: const Icon(Icons.document_scanner),
            label: context.translate('navScanner'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu_outlined),
            selectedIcon: const Icon(Icons.restaurant_menu),
            label: context.translate('navRecipes'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.translate('navSettings'),
          ),
        ],
      ),
    );
  }
}
