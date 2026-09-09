import 'dart:convert';
import 'dart:developer' as developer;
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
    // URL mit Query-Parametern zusammenbauen (168 Schritte entsprechen 7 Tagen à 24 Stunden)
    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/current-forecast',
    ).replace(queryParameters: {
      'model_id': modelId,
      'steps': '168',
    });

    // Debug-Ausgaben streng an den Entwicklungsmodus koppeln
    if (kDebugMode) {
      developer.log('API-LINK (Forecast): $uri', name: 'ForecastApi');
    }

    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      throw Exception('Network error occurred while fetching forecast: $e');
    }

    if (kDebugMode) {
      developer.log('FORECAST STATUS: ${response.statusCode}', name: 'ForecastApi');
    }

    // HTTP-Statusprüfung
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load current forecast (Status: ${response.statusCode})',
      );
    }

    // JSON-Antwort sicher dekodieren und typsicher casten
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Unexpected forecast response format (expected List)');
      }

      // Sichere Konvertierung der Listenelemente zu Map<String, dynamic>
      return decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        }
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    } on FormatException catch (e) {
      throw Exception('Failed to parse forecast JSON response: $e');
    }
  }
}