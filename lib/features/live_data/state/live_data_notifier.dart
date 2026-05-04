import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dto/live_data_dto.dart';
import '../data/dto/weather_station_dto.dart';
import '../data/dto/forecast_dto.dart';
import '../data/repositories/live_data_repository.dart';
import '../data/repositories/forecast_repository.dart';

/// State-Klasse, die alle Datenquellen für die UI bündelt
class LiveDataState {
  final bool isLoading;
  final String? errorMessage;
  final WeatherStationDto? stationData; // Daten Wetterstation (Temp, Wasser, Feuchte)
  final LiveDataDto? modelData;         // Modell-Daten (aus /live-data)
  final List<ForecastDto>? forecast;    // 7-Tage Vorhersage

  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.stationData,
    this.modelData,
    this.forecast,
  });

  LiveDataState copyWith({
    bool? isLoading,
    String? errorMessage,
    WeatherStationDto? stationData,
    LiveDataDto? modelData,
    List<ForecastDto>? forecast,
  }) {
    return LiveDataState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage, // Hier bewusst auf null setzbar
      stationData: stationData ?? this.stationData,
      modelData: modelData ?? this.modelData,
      forecast: forecast ?? this.forecast,
    );
  }
}

class LiveDataNotifier extends StateNotifier<LiveDataState> {
  final LiveDataRepository _liveDataRepository;
  final ForecastRepository _forecastRepository;
  final String _modelId; // z.B. 'icon-eu'

  LiveDataNotifier({
    required LiveDataRepository liveDataRepository,
    required ForecastRepository forecastRepository,
    required String modelId,
  })  : _liveDataRepository = liveDataRepository,
        _forecastRepository = forecastRepository,
        _modelId = modelId,
        super(const LiveDataState()) {
    load();
  }

  /// Lädt Daten von der Wetterstation UND den Wettermodellen
  Future<void> load({String? modelId}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // Nutze modelId vom Aufruf, falls vorhanden, sonst den internen Standard _modelId
      final effectiveModelId = modelId ?? _modelId;

      final results = await Future.wait([
        _liveDataRepository.getWeatherStationData(),
        _forecastRepository.getForecasts(modelId: effectiveModelId),
        _liveDataRepository.getLiveData(),
      ]);

      final stationResult = results[0] as WeatherStationDto?;
      final forecastResult = results[1] as List<ForecastDto>;
      final modelResult = results[2] as LiveDataDto;

      state = LiveDataState(
        isLoading: false,
        stationData: stationResult,
        forecast: forecastResult,
        modelData: modelResult,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
  /// Erlaubt das manuelle Aktualisieren (Pull-to-Refresh)
  Future<void> refresh() => load();
}