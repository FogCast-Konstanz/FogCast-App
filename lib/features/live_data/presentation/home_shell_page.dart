import 'package:flutter/material.dart';
import 'start_page.dart';
import 'expert_page.dart';

/// Die Shell-Hauptseite ([HomeShellPage]) verwaltet die untere Navigation (BottomNavigationBar)
/// und das Umschalten zwischen den Hauptansichten (Live-Daten und Expertenansicht).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

/// Der State für die [HomeShellPage], steuert den aktuell ausgewählten Tab
class _HomeShellPageState extends State<HomeShellPage> {
  // Index des aktuell aktiven Tabs (0 = Live/Start, 1 = Experte)
  int _selectedIndex = 0;

  // Liste der verfügbaren Hauptseiten, die über den Tab-Bar gewechselt werden
  final List<Widget> _pages = const [
    start_page(),
    ExpertPage(),
  ];

  /// Aktualisiert den aktiven Index bei Auswahl eines Tabs in der Navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Farbkonstanten für das Grundlayout und die Navigationsleiste
    const bg = Color(0xFF2B4544);
    const navBarColor = Color(0xFF2B4544);
    const selectedColor = Colors.white;
    const unselectedColor = Colors.white70;

    return Scaffold(
      backgroundColor: bg,
      // IndexedStack sorgt dafür, dass der Zustand der Unterseiten beim Tabwechsel erhalten bleibt
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