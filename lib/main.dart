// I-Fridge — Application Entry Point
// "Zero-Waste, Maximum Taste."

import 'package:flutter/material.dart';
import 'package:ifridge_app/core/theme/app_theme.dart';
import 'package:ifridge_app/features/shelf/presentation/screens/living_shelf_screen.dart';
import 'package:ifridge_app/features/cook/presentation/screens/cook_screen.dart';
import 'package:ifridge_app/features/scan/presentation/screens/scan_screen.dart';
import 'package:ifridge_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tquyodwsyppwbpvkaunn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRxdXlvZHdzeXBwd2JwdmthdW5uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NzEzOTAsImV4cCI6MjA4NzE0NzM5MH0.1o6RYfeL_7YlIeUkl4jFsCm2JCQ2mB2F9o5wLv30xWU',
  );
  runApp(const IFridgeApp());
}

class IFridgeApp extends StatelessWidget {
  const IFridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Fridge',
      debugShowCheckedModeBanner: false,
      theme: IFridgeTheme.darkTheme,
      home: const AppShell(),
    );
  }
}

/// Bottom navigation shell — the root layout of the app.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LivingShelfScreen(),
    CookScreen(),
    ScanScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Shelf',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Cook',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

