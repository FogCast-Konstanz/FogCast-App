import 'package:flutter/material.dart';
import 'start_page.dart';
import 'expert_page.dart';
//import 'settings_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    start_page(),
    expert_page(),
    //SettingsPage(),
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
            icon: Icon(Icons.home),
            label: 'Basic',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Experte',
          ),
        ],
      ),
    );
  }
}