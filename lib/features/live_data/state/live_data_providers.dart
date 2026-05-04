/// Riverpod-Provider für das Live-Data-Feature.
///
/// Architektur:
/// UI → Notifier → Repository → API
///
/// Diese Datei definiert alle Abhängigkeiten (Dependency Injection)
/// für Live-Daten UND Forecast-Daten.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/core/config/environment.dart';
import '../data/api/live_data_api.dart';
import '../data/repositories/live_data_repository.dart';
import '../data/api/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/repositories/forecast_repository.dart';
import 'live_data_notifier.dart';
import '../data/api/history_api.dart';
import '../data/repositories/history_repository.dart';

/// ------------------------------
/// LIVE DATA / WEATHER STATION
/// ------------------------------

/// API für aktuelle Messwerte und Wetterstation
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

/// Repository für Live-Daten und Stationsdaten
final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});

/// ------------------------------
/// FORECAST (Stunden-Vorhersage)
/// ------------------------------

/// API für Forecast (/current-forecast)
final forecastApiProvider = Provider<ForecastApi>((ref) {
  return ForecastApi();
});

/// Repository für Forecast-Daten
final forecastRepositoryProvider = Provider<ForecastRepository>((ref) {
  final api = ref.watch(forecastApiProvider);
  return ForecastRepository(api);
});

/// ------------------------------
/// NOTIFIER
/// ------------------------------

/// StateNotifier Provider
/// Übergibt jetzt explizit die benannten Parameter an den LiveDataNotifier
final liveDataNotifierProvider =
StateNotifierProvider<LiveDataNotifier, LiveDataState>((ref) {
  final liveRepo = ref.watch(liveDataRepositoryProvider);
  final forecastRepo = ref.watch(forecastRepositoryProvider);

  return LiveDataNotifier(
    liveDataRepository: liveRepo,    // Benannter Parameter für Stations- & Live-Daten
    forecastRepository: forecastRepo,  // Benannter Parameter für Modell-Vorhersagen
    modelId: Environment.defaultWeatherModel, // Modell aus der Konfiguration
  );
});

/// Dedizierter Provider nur für den Expertenmodus
final expertLiveDataNotifierProvider = StateNotifierProvider<LiveDataNotifier, LiveDataState>((ref) {
  final liveRepo = ref.watch(liveDataRepositoryProvider);
  final forecastRepo = ref.watch(forecastRepositoryProvider);

  return LiveDataNotifier(
    liveDataRepository: liveRepo,
    forecastRepository: forecastRepo,
    // Hier ist die ID egal, da wir sie in der expert_page explizit beim load() setzen
    modelId: Environment.defaultWeatherModel,
  );
});

/// ------------------------------
/// HISTORY / ARCHIVE
/// ------------------------------

final historyApiProvider = Provider<HistoryApi>((ref) {
  return HistoryApi();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  return HistoryRepository(api);
});