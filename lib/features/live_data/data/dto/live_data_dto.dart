/// Ein Data Transfer Object (DTO) für aktuelle Live-Wetter- und Umweltdaten.
class LiveDataDto {
  /// Die Temperatur in Grad Celsius.
  final double temperature;

  /// Die relative Luftfeuchtigkeit in Prozent.
  final double humidity;

  /// Der Wasserstand in Metern.
  final double waterLevel;

  /// Die Windgeschwindigkeit in Metern pro Sekunde.
  final double windSpeed;

  /// Die Windrichtung in Grad.
  final double windDirection;

  /// Der Luftdruck in Hektopascal (hPa).
  final double airPressure;

  /// Die Windböen in m/s oder 0.0, falls nicht vorhanden.
  final double windGust;

  /// Erstellt eine Instanz von [LiveDataDto].
  LiveDataDto({
    required this.temperature,
    required this.humidity,
    required this.waterLevel,
    required this.windSpeed,
    required this.windDirection,
    required this.airPressure,
    required this.windGust,
  });

  /// Baut ein DTO aus der API-Liste:
  /// [{"name":"temperature","value":"3.0", ...}, ...]
  factory LiveDataDto.fromList(List<dynamic> items) {
    double? temp;
    double? hum;
    double? water;
    double? windSpeed;
    double? windDirection;
    double? airPressure;
    double? windGust;

    // Iteriere durch die Liste der Messwerte und ordne sie zu
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;

      final name = item['name'] as String?;
      final valueStr = item['value']?.toString();

      if (name == null || valueStr == null) continue;

      final value = double.tryParse(valueStr);
      if (value == null) continue;

      switch (name) {
        case 'temperature':
          temp = value;
          break;
        case 'humidity':
          hum = value * 100.0; // Umrechnung von Faktor (0.678) zu Prozent (67.8)
          break;
        case 'water_level':
          water = value / 100.0; // Umrechnung von Zentimeter zu Metern
          break;
        case 'wind_speed':
          windSpeed = value;
          break;
        case 'wind_direction':
          windDirection = value;
          break;
        case 'air_pressure':
          airPressure = value;
          break;
        case 'wind_gust':
          windGust = value;
          break;
      }
    }

    // Prüfen, ob alle essenziellen Messwerte vorhanden sind
    if (temp == null ||
        hum == null ||
        water == null ||
        windSpeed == null ||
        windDirection == null ||
        airPressure == null) {
      throw Exception('LiveData unvollständig: Es fehlen essenzielle Messwerte.');
    }

    return LiveDataDto(
      temperature: temp,
      humidity: hum,
      waterLevel: water,
      windSpeed: windSpeed,
      windDirection: windDirection,
      airPressure: airPressure,
      windGust: windGust ?? 0.0, // Fallback auf 0.0, falls kein Böen-Wert übergeben wurde
    );
  }
}