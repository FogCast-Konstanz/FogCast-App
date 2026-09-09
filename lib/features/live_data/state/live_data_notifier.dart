import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dto/live_data_dto.dart';
import '../data/dto/weather_station_dto.dart';
import '../data/dto/forecast_dto.dart';
import 'live_data_providers.dart';

/// State-Klasse, die alle Datenquellen für die UI bündelt.
class LiveDataState {
  /// Gibt an, ob gerade Daten geladen werden.
  final bool isLoading;

  /// Eventuelle Fehlermeldung während des Ladevorgangs.
  final String? errorMessage;

  /// Die Messdaten der eigenen Wetterstation.
  final WeatherStationDto? stationData;

  /// Die aktuellen Live-Modelldaten.
  final LiveDataDto? modelData;

  /// Die Liste der Vorhersagedaten.
  final List<ForecastDto>? forecast;

  /// Erstellt eine Instanz von [LiveDataState].
  const LiveDataState({
    this.isLoading = false,
    this.errorMessage,
    this.stationData,
    this.modelData,
    this.forecast,
  });

  /// Erstellt eine Kopie des Zustands mit optional geänderten Werten.
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

/// Notifier-Klasse zur Steuerung des gesamten Wetter- und Live-Daten-Zustands.
class LiveDataNotifier extends Notifier<LiveDataState> {
  @override
  LiveDataState build() {
    // Lädt die Daten automatisch asynchron nach dem Rendern der UI
    Future.microtask(() => load());
    return const LiveDataState();
  }

  /// Lädt Daten von der Wetterstation UND den Wettermodellen.
  Future<void> load({String? modelId}) async {
    // Zustand auf Laden setzen und vorherige Fehler zurücksetzen
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

      // Parallel abwarten, bis alle Anfragen abgeschlossen sind
      await Future.wait([stationFuture, forecastFuture, liveDataFuture]);

      // Erfolgreich geladene Daten in den neuen Zustand schreiben
      state = LiveDataState(
        isLoading: false,
        stationData: await stationFuture,
        forecast: await forecastFuture,
        modelData: await liveDataFuture,
      );
    } catch (e) {
      // Im Fehlerfall den Ladezustand beenden und die Fehlermeldung speichern
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  /// Erlaubt das manuelle Aktualisieren (Pull-to-Refresh).
  Future<void> refresh() => load();
}