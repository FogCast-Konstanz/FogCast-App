import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/core/config/environment.dart';
import '../data/api/live_data_api.dart';
import '../data/repositories/live_data_repository.dart';
import '../data/api/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/repositories/forecast_repository.dart';
import 'live_data_notifier.dart';
import '../data/api/history_api.dart';
import '../data/repositories/history_repository.dart';

/// Riverpod-Provider für das Live-Data-Feature.

// Live Data / Weather Station

/// Provider für die [LiveDataApi], stellt die HTTP-Kommunikation für Live-Daten bereit.
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

/// Provider für das [LiveDataRepository], verbindet API und Datenlogik für Live-Daten.
final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});


// Forecast (Stunden-Vorhersage)

/// Provider für die [ForecastApi], wickelt Anfragen bezüglich der Wettervorhersagen ab.
final forecastApiProvider = Provider<ForecastApi>((ref) {
  return ForecastApi();
});

/// Provider für das [ForecastRepository], verwaltet die Vorhersagedaten.
final forecastRepositoryProvider = Provider<ForecastRepository>((ref) {
  final api = ref.watch(forecastApiProvider);
  return ForecastRepository(api);
});

/// Hilfs-Provider für die Standard-Modell-ID aus der Environment-Konfiguration.
final defaultModelIdProvider = Provider<String>((ref) {
  return Environment.defaultWeatherModel;
});

/// Der Haupt-Provider für den [LiveDataNotifier], der den UI-Zustand steuert.
final liveDataNotifierProvider =
NotifierProvider<LiveDataNotifier, LiveDataState>(() {
  return LiveDataNotifier();
});

// History / Archive

/// Provider für die [HistoryApi] zum Abrufen von historischen Archivdaten.
final historyApiProvider = Provider<HistoryApi>((ref) {
  return HistoryApi();
});

/// Provider für das [HistoryRepository] zur Verwaltung der Archivdaten.
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  return HistoryRepository(api);
});