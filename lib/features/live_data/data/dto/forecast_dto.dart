import 'dart:io'; // HttpDate
import 'package:flutter/foundation.dart';

/// Ein Data Transfer Object (DTO) für Wettervorhersagedaten[cite: 5].
///
/// Bildet die rohen JSON-Daten der API auf eine typsichere Dart-Struktur ab.
class ForecastDto {
  /// Der Zeitpunkt der Vorhersage
  final DateTime date;

  /// Gibt an, ob es sich um Tag (`true`) oder Nacht (`false`) handelt
  final bool isDay;

  /// Die Temperatur in Grad Celsius (standardmäßig 2m Höhe)
  final double temperature;

  /// Die Niederschlagsmenge (optional)
  final double? precipitation;

  /// Der numerische Wettercode
  final int? weatherCode;

  /// Die relative Luftfeuchtigkeit in Prozent (relative_humidity_2m)
  final double? humidity;

  /// Die Windgeschwindigkeit (wind_speed_10m oder wind_speed)
  final double? windSpeed;

  /// Die Windrichtung in Grad
  final double? windDirection;

  /// Die Windböen
  final double? windGust;

  /// Die Wolkenbedeckung in Prozent
  final double? cloudCover;

  /// Convective Available Potential Energy (CAPE) Wert
  final double? cape;

  /// Der Luftdruck (pressure_msl oder surface_pressure)
  final double? airPressure;

  /// Erstellt eine Instanz von [ForecastDto]
  ForecastDto({
    required this.date,
    required this.temperature,
    required this.isDay,
    this.precipitation,
    this.weatherCode,
    this.humidity,
    this.windSpeed,
    this.windDirection,
    this.windGust,
    this.cloudCover,
    this.cape,
    this.airPressure,
  });

  /// Hilfsmethode zur sicheren Konvertierung von dynamischen Werten in [double][cite: 5].
  ///
  /// Gibt [null] zurück, wenn der Wert ungültig, keine Zahl oder NaN/Infinity ist
  static double? _numOrNull(dynamic v) {
    if (v is num) {
      final d = v.toDouble();
      if (d.isNaN || !d.isFinite) return null;
      return d;
    }
    return null;
  }

  /// Erstellt ein [ForecastDto] aus einem rohen API-JSON-Eintrag
  factory ForecastDto.fromApiEntry(Map<String, dynamic> json) {
    // Datum parsen (Fallback auf aktuelle Zeit bei ungültigem Format)
    final rawDate = json['forecast_date'];
    final date = (rawDate is String && rawDate.isNotEmpty)
        ? HttpDate.parse(rawDate).toLocal()
        : DateTime.now();

    // Temperatur parsen (Fallback auf 0.0, falls nicht vorhanden)
    final temp = _numOrNull(json['temperature_2m']) ?? 0.0;

    // Niederschlag parsen
    final prec = _numOrNull(json['precipitation']);

    // Wettercode als Integer extrahieren
    final wcRaw = json['weather_code'];
    final wc = (wcRaw is num) ? wcRaw.toInt() : null;

    // Luftfeuchte parsen
    final hum = _numOrNull(json['relative_humidity_2m']);

    // Windgeschwindigkeit und -richtung parsen (mit Fallback auf alternative Keys)
    final ws = _numOrNull(json['wind_speed_10m']) ?? _numOrNull(json['wind_speed']);
    final wd = _numOrNull(json['wind_direction_10m']) ?? _numOrNull(json['wind_direction']);

    // Windböen mit der sicheren _numOrNull-Methode vereinheitlicht
    final windGust = _numOrNull(json['wind_gusts_10m']);

    // Tag/Nacht-Status ermitteln (1 oder 1.0 entspricht true)
    final isDay = json['is_day'] == 1 || json['is_day'] == 1.0;

    // Wolkenbedeckung, CAPE und Luftdruck parsen
    final cloudCover = _numOrNull(json['cloud_cover']);
    final cape = _numOrNull(json['cape']);
    // Die API nutzt oft 'pressure_msl' oder 'surface_pressure'
    final airPressure = _numOrNull(json['pressure_msl']) ?? _numOrNull(json['surface_pressure']);

    return ForecastDto(
      date: date,
      temperature: temp,
      precipitation: prec,
      weatherCode: wc,
      humidity: hum,
      windSpeed: ws,
      windDirection: wd,
      windGust: windGust,
      isDay: isDay,
      cloudCover: cloudCover,
      cape: cape,
      airPressure: airPressure,
    );
  }
}