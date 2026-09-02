import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:fog_cast_app/core/config/environment.dart';

/// Verantwortlich für das Abrufen von historischen Archivdaten von der API
class HistoryApi {
  final http.Client _client;

  /// Erstellt eine Instanz von [HistoryApi].
  ///
  /// Falls kein [client] übergeben wird, wird ein Standard-[http.Client] genutzt
  HistoryApi({http.Client? client}) : _client = client ?? http.Client();

  /// Formatiert ein [DateTime]-Objekt in einen UTC-basierten ISO-8601-String ohne Millisekunden
  String formatDate(DateTime d) {
    return d.toUtc().toIso8601String().split('.').first;
  }

  /// Ruft historische Archivdaten für ein bestimmtes Wetterparameter und Zeitfenster ab[cite: 3].
  ///
  /// [parameter] bezeichnet den abzufragenden Messwert[cite: 3].
  /// [start] und [stop] definieren den Start- und Endzeitpunkt[cite: 3].
  /// [stationId] bestimmt die Stations-ID (Standard ist 1)[cite: 3].
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

    // HTTP-GET-Anfrage an den Server senden
    final response = await _client.get(uri);

    if (kDebugMode) {
      print('HISTORY URL: $uri');
      print('HISTORY STATUS: ${response.statusCode}');
      print('HISTORY RESPONSE: ${response.body}');
    }

    // Bei einem ungültigen Statuscode direkt abbrechen
    if (response.statusCode != 200) {
      throw Exception('Failed to load archive history (${response.statusCode})');
    }

    // JSON-Antwort dekodieren
    final decoded = jsonDecode(response.body);

    // Validieren, ob das Ergebnis wie erwartet eine Liste
    if (decoded is! List) {
      throw Exception('Unexpected archive response (expected List)');
    }

    return decoded;
  }
}