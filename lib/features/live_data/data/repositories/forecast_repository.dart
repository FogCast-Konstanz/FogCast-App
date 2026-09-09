import '../api/forecast_api.dart';
import '../dto/forecast_dto.dart';

/// Repository zur Verwaltung und Bereitstellung von Wettervorhersagedaten.
class ForecastRepository {
  /// Die API-Instanz für den Datenabruf
  final ForecastApi _api;

  /// Erstellt eine Instanz von [ForecastRepository]
  ForecastRepository(this._api);

  /// Ruft die aktuellen Vorhersagen für ein bestimmtes Wettermodell ab
  /// und mappt diese auf typsichere [ForecastDto]-Objekte.
  Future<List<ForecastDto>> getForecasts({
    required String modelId,
  }) async {
    // Rohdaten von der API abrufen
    final raw = await _api.fetchCurrentForecast(modelId: modelId);

    // Die rohen Karteneinträge direkt in DTOs konvertieren
    return raw
        .map((e) => ForecastDto.fromApiEntry(e))
        .toList();
  }
}