import 'dart:convert';
import 'package:flutter/foundation.dart'; // Für kDebugMode
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

/// Verantwortlich für die Kommunikation mit der Wetter-API bezüglich Vorhersagedaten.
class ForecastApi {
  /// Der HTTP-Client, der für Netzwerkanfragen genutzt wird (wählbar für Unit-Tests).
  final http.Client _client;

  /// Erstellt eine Instanz von [ForecastApi].
  ///
  /// Falls kein [client] übergeben wird, wird ein Standard-[http.Client] verwendet.
  ForecastApi({http.Client? client}) : _client = client ?? http.Client();

  /// Ruft die aktuellen Vorhersagedaten für ein spezifisches Modell ab.
  ///
  /// [modelId] identifiziert das verwendete Wettermodell.
  /// Gibt eine Liste von Rohdaten ([List<dynamic>]) der Vorhersage zurück.
  /// Wirft eine [Exception], wenn der HTTP-Statuscode ungleich 200 ist
  /// oder die Antwortstruktur nicht den Erwartungen entspricht.
  Future<List<dynamic>> fetchCurrentForecast({
    required String modelId,
  }) async {
    // Die URL wird hier mit den notwendigen Query-Parametern zusammengebaut.
    // 'steps': '168' sorgt dafür, dass Daten für 7 Tage (7 * 24h) geladen werden.
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/current-forecast',
    ).replace(queryParameters: {
      'model_id': modelId,
      'steps': '168',
    });

    // Debug-Ausgabe nur im Entwicklungsmodus ausführen
    if (kDebugMode) {
      print('API-LINK (Forecast): $uri');
    }

    // HTTP-GET-Anfrage an den Server senden
    final response = await _client.get(uri);

    print('FORECAST STATUS: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load current forecast (${response.statusCode})',
      );
    }

    // JSON-Antwort dekodieren
    final decoded = jsonDecode(response.body);

    // Validieren, ob die Antwort tatsächlich eine Liste ist
    if (decoded is! List) {
      throw Exception('Unexpected forecast response (expected List)');
    }
    return decoded;
  }
}