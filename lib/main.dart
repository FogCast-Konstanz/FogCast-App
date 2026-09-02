import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/features/live_data/presentation/home_shell_page.dart';

/// Der Einstiegspunkt der Anwendung.
///
/// Initialisiert die Flutter-Engine und startet die App innerhalb eines
/// [ProviderScope], um die globale Zustandsverwaltung (Riverpod) zu ermöglichen.
void main() {
  runApp(
    const ProviderScope(
      child: FogCastApp(),
    ),
  );
}

/// Das Root-Widget der FogCast-Anwendung.
///
/// Konfiguriert die globalen App-Einstellungen wie Titel, Design
/// und den initialen Startbildschirm ([HomeShellPage]).
class FogCastApp extends StatelessWidget {
  /// Erstellt eine Instanz von [FogCastApp].
  const FogCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FogCast',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeShellPage(),
    );
  }
}