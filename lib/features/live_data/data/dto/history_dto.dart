import 'dart:io';

/// Ein Data Transfer Object (DTO) für historische Wetter-Archivdaten.
class HistoryDto {
  /// Der Zeitpunkt des historischen Messwertes.
  final DateTime date;

  /// Der gemessene Wert des abgefragten Parameters.
  final double value;

  /// Erstellt eine Instanz von [HistoryDto].
  const HistoryDto({
    required this.date,
    required this.value,
  });

  /// Erstellt ein [HistoryDto] aus einem rohen API-JSON-Eintrag.
  factory HistoryDto.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    final rawValue = json['value'];

    // Datum sicher parsen (Versuch über ISO-8601, HTTP-Date oder Fallback auf aktuelle Zeit)
    DateTime parsedDate = DateTime.now();
    if (rawDate != null) {
      final dateStr = rawDate.toString();
      parsedDate = DateTime.tryParse(dateStr)?.toLocal() ??
          (_tryParseHttpDate(dateStr) ?? DateTime.now());
    }

    // Wert sicher in double konvertieren (mit Fallback auf 0.0 bei ungültigen Typen)
    double parsedValue = 0.0;
    if (rawValue is num) {
      parsedValue = rawValue.toDouble();
    } else if (rawValue is String) {
      parsedValue = double.tryParse(rawValue) ?? 0.0;
    }

    return HistoryDto(
      date: parsedDate,
      value: parsedValue,
    );
  }

  /// Interne Hilfsfunktion zum Parsen von HTTP-Datumsformaten als Fallback.
  static DateTime? _tryParseHttpDate(String dateStr) {
    try {
      return HttpDate.parse(dateStr).toLocal();
    } catch (_) {
      return null;
    }
  }
}