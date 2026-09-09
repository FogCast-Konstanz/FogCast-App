import '../api/history_api.dart';
import '../dto/history_dto.dart';

/// Repository zur Verwaltung und Bereitstellung von historischen Archivdaten.
class HistoryRepository {
  /// Die API-Instanz für den Datenabruf
  final HistoryApi _api;

  /// Erstellt eine Instanz von [HistoryRepository]
  HistoryRepository(this._api);

  /// Ruft historische Archivdaten für einen Parameter und Zeitraum ab
  /// und mappt diese auf typsichere [HistoryDto]-Objekte
  Future<List<HistoryDto>> getArchiveHistory({
    required String parameter,
    required DateTime start,
    required DateTime stop,
    int stationId = 1,
    String period = 'd',
  }) async {
    // Rohdaten von der API abrufen
    final raw = await _api.fetchArchiveHistory(
      parameter: parameter,
      start: start,
      stop: stop,
      stationId: stationId,
      period: period,
    );

    // Die rohen Karteneinträge direkt in DTOs konvertieren
    return raw
        .map((e) => HistoryDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}