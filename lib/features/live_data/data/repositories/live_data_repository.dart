import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../api/live_data_api.dart';
import '../dto/live_data_dto.dart';
import '../dto/weather_station_dto.dart';

/// Repository für das Feature "Live Data".
///
/// Das Repository bildet die Mittelschicht zwischen API und State.
/// Es ruft die HTTP-Endpunkte über [LiveDataApi] auf und wandelt die
/// JSON-Antworten in stark typisierte Dart-Objekte um.
///
/// Die UI und der State arbeiten ausschließlich mit [LiveDataDto],
/// nicht mit JSON-Maps. Dadurch bleiben Netzwerklayer und Datenmodell
/// klar voneinander getrennt.
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
    // Rohe Daten von der API abrufen
    final raw = await _api.fetchLiveData();

    // Prüfen, ob die Antwort eine Liste ist und in das DTO mappen
    if (raw is List) {
      return LiveDataDto.fromList(raw);
    }

    throw Exception('Unexpected response format: ${raw.runtimeType}');
  }

  /// Ruft die Daten der Wetterstation ab.
  ///
  /// Dank der rekursiven Logik in [LiveDataApi] wird automatisch
  /// in der Zeit zurückgegangen, wenn keine Daten vorhanden sind.
  ///
  /// Gibt ein [WeatherStationDto] zurück oder `null`, falls auch nach
  /// mehreren Versuchen keine Daten gefunden wurden.
  Future<WeatherStationDto?> getWeatherStationData() async {
    try {
      // Die API-Methode liefert bereits den passenden (letzten) Datensatz
      // oder null nach 7 Tagen erfolgloser Suche.
      final json = await _api.fetchWeatherStationData();

      if (json == null) {
        return null;
      }

      // Umwandlung der Map in das typisierte DTO.
      return WeatherStationDto.fromJson(json as Map<String, dynamic>);
    } catch (e) {
      // Fehler über developer.log statt print ausgeben
      if (kDebugMode) {
        developer.log(
          'Error in LiveDataRepository.getWeatherStationData: $e',
          name: 'LiveDataRepository',
        );
      }
      return null;
    }
  }
}