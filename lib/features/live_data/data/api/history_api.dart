import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

/// Verantwortlich für das Abrufen von historischen Archivdaten von der API
class HistoryApi {
  /// Der HTTP-Client, der für Netzwerkanfragen genutzt wird.
  final http.Client _client;

  /// Erstellt eine Instanz von [HistoryApi].
  ///
  /// Falls kein [client] übergeben wird, wird ein Standard-[http.Client] genutzt
  HistoryApi({http.Client? client}) : _client = client ?? http.Client();

  /// Formatiert ein [DateTime]-Objekt in einen UTC-basierten ISO-8601-String ohne Millisekunden
  String formatDate(DateTime d) {
    return d.toUtc().toIso8601String().split('.').first;
  }

  /// Ruft historische Archivdaten für ein bestimmtes Wetterparameter und Zeitfenster ab
  ///
  /// [parameter] bezeichnet den abzufragenden Messwert.
  /// [start] und [stop] definieren den Start- und Endzeitpunkt.
  /// [stationId] bestimmt die Stations-ID (Standard ist 1).
  /// [period] gibt das Intervall an (Standard ist 'd' für täglich)
  Future<List<dynamic>> fetchArchiveHistory({
    required String parameter,
    required DateTime start,
    required DateTime stop,
    int stationId = 1,
    String period = 'd',
  }) async {
    // URL für den Endpunkt mit allen erforderlichen Query-Parametern zusammenbauen
    final uri = Uri.parse('${Environment.apiBaseUrl}/archive/$parameter').replace(
      queryParameters: {
        'start': formatDate(start),
        'stop': formatDate(stop),
        'station_id': stationId.toString(),
        'period': period,
      },
    );

    // Debug-Ausgaben an den Entwicklungsmodus koppeln
    if (kDebugMode) {
      developer.log('HISTORY URL: $uri', name: 'HistoryApi');
    }

    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      throw Exception('Network error occurred while fetching history: $e');
    }

    if (kDebugMode) {
      developer.log('HISTORY STATUS: ${response.statusCode}', name: 'HistoryApi');
      developer.log('HISTORY RESPONSE: ${response.body}', name: 'HistoryApi');
    }

    // Bei einem ungültigen Statuscode direkt abbrechen
    if (response.statusCode != 200) {
      throw Exception('Failed to load archive history (Status: ${response.statusCode})');
    }

    // JSON-Antwort dekodieren und typsicher validieren
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! List) {
        throw Exception('Unexpected archive response format (expected List)');
      }

      // Konvertierung in eine Liste von Maps für Typsicherheit
      return decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return item;
        }
        return Map<String, dynamic>.from(item as Map);
      }).toList();
    } on FormatException catch (e) {
      throw Exception('Failed to parse history JSON response: $e');
    }
  }
}