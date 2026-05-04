/// Stellt die HTTP-Kommunikation für das Feature "Live Data" bereit.
///
/// Diese Klasse ist ausschließlich dafür zuständig, Requests an die
/// Backend-API zu senden und die rohen JSON-Antworten zurückzugeben.
/// Sie enthält keinerlei Business-Logik – diese befindet sich im Repository.
///
/// Verwendet wird standardmäßig ein [http.Client], der optional beim
/// Erstellen der Klasse überschrieben werden kann (z. B. für Tests).

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/environment.dart';

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
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load live data (${response.statusCode})');
    }

    // DEBUG: API-Antwort im Log ausgeben
    print('LIVE DATA RESPONSE:');
    print(response.body);

    return jsonDecode(response.body);
  }

  /// Abfrage der Daten der Wetterstation.
  ///
  /// Falls die Wetterstation keine Daten für den angefragten Zeitraum liefert,
  /// wird der Start- und Endzeitpunkt schrittweise um jeweils einen Tag nach hinten verschoben.
  /// Der [daysOffset] gibt an, wie viele Tage vom aktuellen Zeitpunkt zurückgegangen wird.
  Future<dynamic> fetchWeatherStationData({int daysOffset = 0}) async {
    if (daysOffset > 7) {
      print('WEATHERSTATION: Auch nach 7 Tagen keine Daten gefunden.');
      return null;
    }

    final now = DateTime.now().toUtc().subtract(Duration(days: daysOffset));
    final start = now.subtract(const Duration(hours: 24));

    String formatApiDate(DateTime dt) {
      return dt.toIso8601String().split('.').first + 'Z';
    }

    final startStr = formatApiDate(start);
    final stopStr = formatApiDate(now);

    final baseUrl = Environment.apiBaseUrl.endsWith('/')
        ? Environment.apiBaseUrl
        : '${Environment.apiBaseUrl}/';

    final uri = Uri.parse('${baseUrl}weatherstation?start=$startStr&stop=$stopStr');

    print('WEATHERSTATION URL (Versuch mit Offset -$daysOffset Tage): $uri');

    try {
      final response = await _client.get(uri);
      print('WEATHERSTATION STATUS: ${response.statusCode}');

      // Fall 1: Erfolg (200)
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lastEntry = data.last;

          // NEU: Detailliertes Logging des erfolgreichen Datensatzes
          print('WEATHERSTATION: Daten erfolgreich gefunden (Offset: $daysOffset).');
          print('ERFOLGREICHER DATENSATZ: $lastEntry');

          return lastEntry;
        } else {
          print('WEATHERSTATION: Liste leer. Springe einen Tag zurück...');
          return await fetchWeatherStationData(daysOffset: daysOffset + 1);
        }
      }
      // Fall 2: Server-Fehler (500) - In diesem Fall interpretieren wir das als "keine Daten"
      else if (response.statusCode == 500) {
        print('WEATHERSTATION: Server-Fehler 500. Versuche es einen Tag früher...');
        return await fetchWeatherStationData(daysOffset: daysOffset + 1);
      }
      // Fall 3: Andere Fehler (404, 401 etc.)
      else {
        throw Exception('Failed to load weatherstation data (${response.statusCode})');
      }
    } catch (e) {
      // Falls es ein Netzwerkfehler ist oder der 500er oben geworfen wurde
      print('WEATHERSTATION ERROR: $e');
      // Auch bei Fehlern versuchen wir, einen Tag zurückzugehen, sofern es kein
      // kritischer Fehler ist, der die App stoppen sollte.
      if (daysOffset < 7) {
        return await fetchWeatherStationData(daysOffset: daysOffset + 1);
      }
      rethrow;
    }
  }
}