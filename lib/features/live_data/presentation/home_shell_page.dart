import 'package:flutter/material.dart';
import 'start_page.dart';
import 'expert_page.dart'; // Hier importierst du die expert_page.dart

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    start_page(),
    ExpertPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B4544);
    const navBarColor = Color(0xFF2B4544);
    const selectedColor = Colors.white;
    const unselectedColor = Colors.white70;

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: navBarColor,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wb_sunny),
            label: 'Live',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Experte',
          ),
        ],
      ),
    );
  }
}