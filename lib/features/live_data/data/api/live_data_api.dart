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
  ///
  /// Ablauf:
  /// 1. URL wird aus der [Environment.apiBaseUrl] + Endpoint gebaut.
  /// 2. GET-Request wird ausgeführt.
  /// 3. Bei Statuscode ≠ 200 wird eine Exception geworfen.
  /// 4. Der Response-Body wird als `Map<String, dynamic>` zurückgegeben.
  ///
  /// Diese Methode liefert nur rohes JSON. Das Mapping in typisierte
  /// Datenobjekte erfolgt im Repository.

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

  // Abfrage der Daten der Wetterstation
  Future<dynamic> fetchWeatherStationData() async {
    final now = DateTime.now().toUtc();
    final start = now.subtract(const Duration(hours: 24));

    // Formatierung für die API (YYYY-MM-DDTHH:MM:SSZ)
    String formatApiDate(DateTime dt) {
      return dt.toIso8601String().split('.').first + 'Z';
    }

    final startStr = formatApiDate(start);
    final stopStr = formatApiDate(now);

    // Basis-URL sauber zusammenbauen
    final baseUrl = Environment.apiBaseUrl.endsWith('/')
        ? Environment.apiBaseUrl
        : '${Environment.apiBaseUrl}/';

    // Der vollständige Link
    final uri = Uri.parse(
        '${baseUrl}weatherstation?start=$startStr&stop=$stopStr'
    );

    // HIER: Den Link in der Konsole ausgeben
    print('WEATHERSTATION URL: $uri');

    final response = await _client.get(uri);

    // Zusätzliches Logging für die Antwort
    print('WEATHERSTATION STATUS: ${response.statusCode}');
    print('LIVE URL: $uri');
    print('LIVE STATUS: ${response.statusCode}');
    print('LIVE BODY: ${response.body}');

    if (response.statusCode != 200) {
      print('WEATHERSTATION ERROR BODY: ${response.body}');
      throw Exception('Failed to load weatherstation data (${response.statusCode})');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.isNotEmpty ? data.last : null;
  }
}