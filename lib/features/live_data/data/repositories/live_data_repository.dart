/// Repository für das Feature "Live Data".
///
/// Das Repository bildet die Mittelschicht zwischen API und State.
/// Es ruft die HTTP-Endpunkte über [LiveDataApi] auf und wandelt die
/// JSON-Antworten in stark typisierte Dart-Objekte um.
///
/// Die UI und der State arbeiten ausschließlich mit [LiveDataDto],
/// nicht mit JSON-Maps. Dadurch bleiben Netzwerklayer und Datenmodell
/// klar voneinander getrennt.

import '../api/live_data_api.dart';
import '../dto/live_data_dto.dart';
import '../dto/weather_station_dto.dart';

class LiveDataRepository {
  /// API-Klasse, die die HTTP-Requests ausführt.
  final LiveDataApi _api;

  /// Erstellt ein neues Repository, dem eine [LiveDataApi]
  /// übergeben wird (oft injiziert durch Riverpod)[cite: 1].
  LiveDataRepository(this._api);

  /// Holt die aktuellen Live-Daten vom Backend.
  ///
  /// Ablauf:
  /// 1. API wird über [_api.fetchLiveData()] aufgerufen[cite: 1].
  /// 2. JSON wird empfangen und dekodiert[cite: 1].
  /// 3. JSON wird in ein [LiveDataDto] umgewandelt.
  Future<LiveDataDto> getLiveData() async {
    final raw = await _api.fetchLiveData();

    if (raw is List) {
      return LiveDataDto.fromList(raw);
    }

    throw Exception('Unexpected response format: ${raw.runtimeType}');
  }

  /// Ruft die Daten der Wetterstation ab.
  ///
  /// Dank der rekursiven Logik in [LiveDataApi] wird automatisch
  /// in der Zeit zurückgegangen, wenn keine Daten vorhanden sind[cite: 1].
  ///
  /// Gibt ein [WeatherStationDto] zurück oder `null`, falls auch nach
  /// mehreren Versuchen keine Daten gefunden wurden[cite: 2].
  Future<WeatherStationDto?> getWeatherStationData() async {
    try {
      // Die API-Methode liefert bereits den passenden (letzten) Datensatz
      // oder null nach 7 Tagen erfolgloser Suche[cite: 1].
      final json = await _api.fetchWeatherStationData();

      if (json == null) {
        return null;
      }

      // Umwandlung der Map in das typisierte DTO[cite: 2].
      return WeatherStationDto.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      // Fehler-Logging (optional)
      print('Error in LiveDataRepository.getWeatherStationData: $e');
      return null;
    }
  }
}