import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dto/live_data_dto.dart';
import '../data/dto/weather_station_dto.dart';
import '../data/dto/forecast_dto.dart';
import 'live_data_providers.dart';

/// State-Klasse, die alle Datenquellen für die UI bündelt
class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final WeatherStationDto? stationData;
  final LiveDataDto? modelData;
  final List<ForecastDto>? forecast;

  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.stationData,
    this.modelData,
    this.forecast,
  });

  LiveDataState copyWith({
    bool? isLoading,
    String? Function()? errorMessage,
    WeatherStationDto? stationData,
    LiveDataDto? modelData,
    List<ForecastDto>? forecast,
  }) {
    return LiveDataState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      stationData: stationData ?? this.stationData,
      modelData: modelData ?? this.modelData,
      forecast: forecast ?? this.forecast,
    );
  }
}

class LiveDataNotifier extends Notifier<LiveDataState> {
  @override
  LiveDataState build() {
    // Lädt die Daten automatisch asynchron nach dem Rendern der UI
    Future.microtask(() => load());
    return const LiveDataState();
  }

  /// Lädt Daten von der Wetterstation UND den Wettermodellen
  Future<void> load({String? modelId}) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final liveDataRepository = ref.read(liveDataRepositoryProvider);
      final forecastRepository = ref.read(forecastRepositoryProvider);

      // Garantiert einen non-nullable String, da defaultModelIdProvider einen String liefert
      final String effectiveModelId = modelId ?? ref.read(defaultModelIdProvider);

      // Typsichere Definition der Futures vor dem parallelen Abruf
      final Future<WeatherStationDto?> stationFuture = liveDataRepository.getWeatherStationData();
      final Future<List<ForecastDto>> forecastFuture = forecastRepository.getForecasts(modelId: effectiveModelId);
      final Future<LiveDataDto> liveDataFuture = liveDataRepository.getLiveData();

      // Parallel abwarten
      await Future.wait([stationFuture, forecastFuture, liveDataFuture]);

      state = LiveDataState(
        isLoading: false,
        stationData: await stationFuture,
        forecast: await forecastFuture,
        modelData: await liveDataFuture,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  /// Erlaubt das manuelle Aktualisieren (Pull-to-Refresh)
  Future<void> refresh() => load();
}