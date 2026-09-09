import 'dart:io';

/// Ein Data Transfer Object (DTO) für Messdaten der eigenen Wetterstation.
class WeatherStationDto {
  /// Der Zeitstempel der Messung.
  final DateTime timestamp;

  /// Die gemessene Lufttemperatur in Grad Celsius.
  final double temperature;

  /// Die relative Luftfeuchtigkeit in Prozent.
  final double humidity;

  /// Die Wassertemperatur in Grad Celsius.
  final double waterTemperature;

  /// Erstellt eine Instanz von [WeatherStationDto].
  const WeatherStationDto({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.waterTemperature,
  });

  /// Erstellt ein [WeatherStationDto] aus einem rohen API-JSON-Eintrag.
  factory WeatherStationDto.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    final timeStr = json['time']?.toString();

    if (timeStr != null && timeStr.isNotEmpty) {
      // Primär versuchen, als ISO-8601-String zu parsen (Standard für moderne APIs)
      parsedDate = DateTime.tryParse(timeStr)?.toLocal() ??
          (_tryParseHttpDate(timeStr) ?? DateTime.now());
    }

    return WeatherStationDto(
      timestamp: parsedDate,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0.0,
      waterTemperature: (json['water_temperature'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Interne Hilfsfunktion zum Parsen von HTTP-Datumsformaten (z. B. "Mon, 13 Apr 2026...") als Fallback.
  static DateTime? _tryParseHttpDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }
}