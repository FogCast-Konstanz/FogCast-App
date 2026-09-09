import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/environment.dart';

/// Stellt die HTTP-Kommunikation für das Feature "Live Data" bereit.
///
/// Diese Klasse ist ausschließlich dafür zuständig, Requests an die
/// Backend-API zu senden und die rohen JSON-Antworten zurückzugeben.
/// Sie enthält keinerlei Business-Logik – diese befindet sich im Repository.
///
/// Verwendet wird standardmäßig ein [http.Client], der optional beim
/// Erstellen der Klasse überschrieben werden kann (z. B. für Tests).
class LiveDataApi {
  /// HTTP-Client, über den alle Requests laufen.
  final http.Client _client;

  /// Erstellt eine neue Instanz der [LiveDataApi].
  ///
  /// Wenn kein eigener [http.Client] übergeben wird, wird automatisch
  /// ein Standard-Client erzeugt.
  LiveDataApi({http.Client? client}) : _client = client ?? http.Client();

  /// Ruft den Endpoint `/actual/live-data` des Backends auf und gibt die
  /// Antwort als dekodiertes JSON-Objekt zurück.
  Future<dynamic> fetchLiveData() async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/actual/live-data');

    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      throw Exception('Network error occurred while fetching live data: $e');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load live data (Status: ${response.statusCode})');
    }

    if (kDebugMode) {
      developer.log('LIVE DATA RESPONSE: ${response.body}', name: 'LiveDataApi');
    }

    try {
      return jsonDecode(response.body);
    } on FormatException catch (e) {
      throw Exception('Failed to parse live data JSON response: $e');
    }
  }

  /// Formatiert ein [DateTime]-Objekt in einen ISO-8601-String mit 'Z' (UTC).
  String _formatApiDate(DateTime dt) {
    return dt.toIso8601String().split('.').first + 'Z';
  }

  /// Abfrage der Daten der Wetterstation.
  ///
  /// Falls die Wetterstation keine Daten für den angefragten Zeitraum liefert,
  /// wird der Start- und Endzeitpunkt schrittweise um jeweils einen Tag nach hinten verschoben.
  /// Der [daysOffset] gibt an, wie viele Tage vom aktuellen Zeitpunkt zurückgegangen wird.
  Future<dynamic> fetchWeatherStationData({int daysOffset = 0}) async {
    if (daysOffset > 7) {
      if (kDebugMode) {
        print('WEATHERSTATION: Auch nach 7 Tagen keine Daten gefunden.');
      }
      return null;
    }

    final now = DateTime.now().toUtc().subtract(Duration(days: daysOffset));
    final start = now.subtract(const Duration(hours: 24));

    final startStr = _formatApiDate(start);
    final stopStr = _formatApiDate(now);

    final uri = Uri.parse(Environment.apiBaseUrl)
        .resolve('weatherstation')
        .replace(queryParameters: {
      'start': startStr,
      'stop': stopStr,
    });

    if (kDebugMode) {
      developer.log('WEATHERSTATION URL (Versuch mit Offset -$daysOffset Tage): $uri', name: 'LiveDataApi');
    }

    try {
      final response = await _client.get(uri);

      if (kDebugMode) {
        developer.log('WEATHERSTATION STATUS: ${response.statusCode}', name: 'LiveDataApi');
      }

      // Fall 1: Erfolg (200)
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Unexpected weather station response format (expected List)');
        }

        if (decoded.isNotEmpty) {
          final lastEntry = decoded.last;

          if (kDebugMode) {
            developer.log('WEATHERSTATION: Daten erfolgreich gefunden (Offset: $daysOffset).', name: 'LiveDataApi');
            developer.log('ERFOLGREICHER DATENSATZ: $lastEntry', name: 'LiveDataApi');
          }

          return lastEntry;
        } else {
          if (kDebugMode) {
            developer.log('WEATHERSTATION: Liste leer. Springe einen Tag zurück...', name: 'LiveDataApi');
          }
          return await fetchWeatherStationData(daysOffset: daysOffset + 1);
        }
      }
      // Fall 2: Server-Fehler (500) - Als "keine Daten" interpretieren
      else if (response.statusCode == 500) {
        if (kDebugMode) {
          developer.log('WEATHERSTATION: Server-Fehler 500. Versuche es einen Tag früher...', name: 'LiveDataApi');
        }
        return await fetchWeatherStationData(daysOffset: daysOffset + 1);
      }
      // Fall 3: Andere Fehler (404, 401 etc.)
      else {
        throw Exception('Failed to load weatherstation data (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('WEATHERSTATION ERROR: $e', name: 'LiveDataApi');
      }

      if (daysOffset < 7) {
        return await fetchWeatherStationData(daysOffset: daysOffset + 1);
      }
      rethrow;
    }
  }
}