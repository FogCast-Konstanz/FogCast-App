/// Riverpod-Provider für das Live-Data-Feature.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/core/config/environment.dart';
import '../data/api/live_data_api.dart';
import '../data/repositories/live_data_repository.dart';
import '../data/api/forecast_api.dart';
import 'package:fog_cast_app/features/live_data/data/repositories/forecast_repository.dart';
import 'live_data_notifier.dart';
import '../data/api/history_api.dart';
import '../data/repositories/history_repository.dart';

// LIVE DATA / WEATHER STATION
final liveDataApiProvider = Provider<LiveDataApi>((ref) {
  return LiveDataApi();
});

final liveDataRepositoryProvider = Provider<LiveDataRepository>((ref) {
  final api = ref.watch(liveDataApiProvider);
  return LiveDataRepository(api);
});


// FORECAST (Stunden-Vorhersage)
final forecastApiProvider = Provider<ForecastApi>((ref) {
  return ForecastApi();
});

final forecastRepositoryProvider = Provider<ForecastRepository>((ref) {
  final api = ref.watch(forecastApiProvider);
  return ForecastRepository(api);
});

// Neuer Hilfs-Provider für die Standard-Modell-ID aus deiner Environment-Konfiguration
final defaultModelIdProvider = Provider<String>((ref) {
  return Environment.defaultWeatherModel;
});

// Der Haupt-Provider für den normalen LiveDataNotifier
final liveDataNotifierProvider =
    NotifierProvider<LiveDataNotifier, LiveDataState>(() {
      return LiveDataNotifier();
    });

// HISTORY / ARCHIVE
final historyApiProvider = Provider<HistoryApi>((ref) {
  return HistoryApi();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final api = ref.watch(historyApiProvider);
  return HistoryRepository(api);
});
