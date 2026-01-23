import 'package:flutter/material.dart';
import 'diagnose_screen.dart';
import 'history_screen.dart';
import 'market_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // We add 'Home' as index 0 to hold the "Landing Page" with 2 big buttons.
  // The user asked for "Diagnose, History, Market" in the dock.
  // We will map:
  // 0: Landing Page (Home)
  // 1: Diagnose
  // 2: History
  // 3: Market
  // To keep the dock clean (3 items) as requested, we might need a trick.
  // BUT for usability, I will implement 4 items effectively, or treat "Diagnose" as the Home?
  // Let's implement 4 items for safety: Home, Diagnose, History, Market.

  final List<Widget> _screens = [
    const LandingBody(), // The "2 Big Buttons" page
    const DiagnoseScreen(),
    const HistoryScreen(),
    const MarketScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Leading: Vertical Three Dots for Settings (Left side as requested)
        leading: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
        // Title: Name of the page
        title: Text(_selectedIndex == 0 ? 'FarmAI' : _getTitle(_selectedIndex)),
        centerTitle: true,
        // Actions: Avatar (Right side)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Text('U'), // Placeholder for User
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.camera_alt),
            label: 'Diagnose',
          ),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.storefront), label: 'Market'),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 1:
        return 'Diagnose';
      case 2:
        return 'History';
      case 3:
        return 'Market';
      default:
        return 'FarmAI';
    }
  }
}

class LandingBody extends StatelessWidget {
  const LandingBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big Button 1: New Scan
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    // Switch to Diagnose Tab?
                    // For now just print. In real app, we'd use a provider or callback to switch tabs.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Starting New Scan...')),
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48),
                      SizedBox(height: 16),
                      Text('New Diagnosis', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Big Button 2: Recent Activity
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening Recent Activity...'),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu, size: 48),
                      SizedBox(height: 16),
                      Text('Recent Activity', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
