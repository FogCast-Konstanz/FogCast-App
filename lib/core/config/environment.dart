/// Verwaltet globale Konfigurationsvariablen und Umgebungsparameter der Anwendung.
///
/// Diese Klasse bündelt Konstanten wie Basis-URLs für Netzwerkanfragen
/// und Standardwerte für Wettermodelle an einem zentralen Ort.
class Environment {
  /// Die Basis-URL für alle API-Anfragen der Wetter-App.
  static const String apiBaseUrl = 'https://fogcast.in.htwg-konstanz.de/api/';
  /// Das standardmäßig verwendete Wettermodell für Vorhersagen.
  static const String defaultWeatherModel = 'icon_global';
}