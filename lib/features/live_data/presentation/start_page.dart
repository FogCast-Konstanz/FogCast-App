import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';
import '../presentation/forecast_detail_page.dart';

/// Die Startseite ([start_page]) der App, die aktuelle Live-Wetterdaten
/// der eigenen Station sowie stündliche und mehrtägige Vorhersagen anzeigt.
class start_page extends ConsumerStatefulWidget {
  /// Erstellt eine Instanz von [start_page].
  const start_page({super.key});

  @override
  ConsumerState<start_page> createState() => DashboardPageState();
}

/// Der State der [start_page], der für das Laden der Daten und den Aufbau der Dashboard-UI verantwortlich ist.
class DashboardPageState extends ConsumerState<start_page> {
  @override
  void initState() {
    super.initState();
    // Lädt beim Öffnen der Seite die Daten über den Notifier
    Future.microtask(() => ref.read(liveDataNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    // Beobachtet den aktuellen Zustand des Live-Data-Providers
    final state = ref.watch(liveDataNotifierProvider);

    // Design-Farbkonstanten basierend auf dem Figma-Entwurf
    const bg = Color(0xFF2B4544); // Dunkles Grün/Teal als Hintergrund
    const tile = Color(0xFF5E8886); // Standard Kachelfarbe
    const tileDark = Color(0xFF4F7876); // Etwas dunklere Kachelfarbe
    const white = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'FOGCAST',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        iconTheme: const IconThemeData(color: white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Builder(
            builder: (_) {
              // Status 1: Zeige einen Ladeindikator während des Datenabrufs
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              // Status 2: Zeige eine Fehlermeldung, falls beim Laden ein Fehler aufgetreten ist
              if (state.errorMessage != null) {
                return Center(
                  child: _RoundedTile(
                    color: tile,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fehler:\n${state.errorMessage}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: white),
                        ),
                        const SizedBox(height: 12),
                        _PrimaryPillButton(
                          text: 'Erneut laden',
                          onPressed: () =>
                              ref.read(liveDataNotifierProvider.notifier).load(),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Status 3: Fallback, falls Stationsdaten null sind
              if (state.stationData == null) {
                return Center(
                  child: _PrimaryPillButton(
                    text: 'Daten laden',
                    onPressed: () =>
                        ref.read(liveDataNotifierProvider.notifier).load(),
                  ),
                );
              }

              // Extrahieren der Stations- und Vorhersagedaten aus dem State
              final station = state.stationData!;
              final forecast = state.forecast ?? <ForecastDto>[];
              debugPrint('FORECAST count: ${forecast.length}');
              if (forecast.isNotEmpty) {
                debugPrint('FORECAST first: ${forecast.first.date}');
                debugPrint('FORECAST last : ${forecast.last.date}');
              }

              final now = DateTime.now();

              // Vorhersagedaten chronologisch sortieren
              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));
              // Filtern der nächsten 24 Stunden ab dem aktuellen Zeitpunkt
              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(24)
                  .toList();

              // 1. Gruppierung der vorhandenen Vorhersagedaten nach Tagen
              final Map<String, List<ForecastDto>> groupedByDay = {};
              for (var f in forecast) {
                final dayKey = "${f.date.year}-${f.date.month}-${f.date.day}";
                groupedByDay.putIfAbsent(dayKey, () => []).add(f);
              }

              // 2. Fixierte 7-Tage-Reihenfolge generieren (beginnend mit heute)
              final List<String> potentialDayKeys = List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index));
                return "${date.year}-${date.month}-${date.day}";
              });

              // 3. Nur Tage behalten, für die auch Modelldaten vorliegen, um Null-Fehler zu vermeiden
              final dayKeys = potentialDayKeys.where((key) => groupedByDay.containsKey(key)).toList();

              // Info anzeigen, falls gar keine Vorhersage-Daten verfügbar sind
              if (dayKeys.isEmpty) {
                return const Center(child: Text("Keine Vorhersagedaten für dieses Modell verfügbar", style: TextStyle(color: Colors.white)));
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top: 4 KPI-Kacheln für Live-Werte der Wetterstation ---
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.water_drop,
                            value: station.humidity.toStringAsFixed(0),
                            unit: '%',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.thermostat,
                            value: station.temperature.toStringAsFixed(0),
                            unit: '°',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.waves,
                            value: station.waterTemperature.toStringAsFixed(1),
                            unit: '°C',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(
                            color: tile,
                            icon: Icons.air,
                            // Windgeschwindigkeit wird aus dem Wettermodell bezogen

                            value: forecast.isNotEmpty
                                ? (forecast.first.windSpeed?.toStringAsFixed(1) ?? '--')
                                : '--',
                            unit: 'km/h',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- Forecast: Stündliche Vorhersage als horizontale Liste ---
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _HourForecastTile(
                              color: tileDark,
                              dto: hours[i],
                            );
                          },
                        ),
                      )
                    else
                      _RoundedTile(
                        color: tileDark,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Keine Vorhersagedaten für heute verfügbar',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: white),
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // --- Unten: 7-Tage-Übersichtskachel ---
                    _RoundedTile(
                      color: tile,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            if (dayKeys.isEmpty)
                              const Text("Keine Wochendaten verfügbar", style: TextStyle(color: white))
                            else
                              ...dayKeys.map((key) {
                                final dayData = groupedByDay[key]!;

                                // 1. Alle Wetter-Codes dieses Tages sammeln
                                final List<int> dailyCodes = dayData.map((f) => f.weatherCode ?? 0).toList();

                                // 2. Häufigsten Wettercode ermitteln (Modalwert)
                                final Map<int, int> occurrences = {};
                                for (var code in dailyCodes) {
                                  occurrences[code] = (occurrences[code] ?? 0) + 1;
                                }

                                final mostFrequentCode = occurrences.entries
                                    .reduce((a, b) => a.value > b.value ? a : b)
                                    .key;

                                // 3. Minimal- und Maximaltemperatur für den Tag berechnen
                                double minT = dayData.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
                                double maxT = dayData.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);

                                return _DayRow(
                                  label: _getWeekdayLabel(dayData.first.date),
                                  emoji: _weatherEmojiFromCode(mostFrequentCode, true),
                                  left: '${minT.round()}°',
                                  right: '${maxT.round()}°',
                                  // Navigation zur Detailseite bei Klick auf einen Tag
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ForecastDetailPage(
                                          selectedDate: dayData.first.date,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),

                            const SizedBox(height: 10),
                            _PrimaryPillButton(
                              text: 'Aktualisieren',
                              onPressed: () => ref.read(liveDataNotifierProvider.notifier).load(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ---------- UI Bausteine (Kacheln) ----------

/// Ein abgerundeter Container zur Strukturierung von Inhalten.
class _RoundedTile extends StatelessWidget {
  final Widget child;
  final Color color;

  const _RoundedTile({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

/// Ein Kachel-Widget für einzelne Messwerte (Metriken/KPIs).
class _MetricTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String value;
  final String unit;

  const _MetricTile({
    required this.color,
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Icon(icon, color: white, size: 22),

          const SizedBox(height: 8),

          // Wert (skaliert automatisch bei langen Texten)
          SizedBox(
            height: 32,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          // Einheit
          SizedBox(
            height: 16,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                unit,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kachel für die stündliche Vorhersage in der horizontalen Leiste.
class _HourForecastTile extends StatelessWidget {
  final Color color;
  final ForecastDto dto;

  const _HourForecastTile({
    required this.color,
    required this.dto,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final hour = dto.date.hour;

    return Container(
      width: (MediaQuery.of(context).size.width - 36 - 36) / 4,
      height: 130,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Uhrzeit
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),

          const SizedBox(height: 6),

          // Wetter-Emoji
          Text(
            _weatherEmojiFromCode(dto.weatherCode, dto.isDay),
            style: const TextStyle(fontSize: 30),
          ),

          const SizedBox(height: 6),

          // Temperatur
          SizedBox(
            height: 18,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${dto.temperature.toStringAsFixed(0)}°C',
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ),
          ),

          const SizedBox(height: 2),

          // Niederschlagsmenge
          SizedBox(
            height: 12,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${(dto.precipitation ?? 0).toStringAsFixed(0)}mm',
                style: const TextStyle(
                  color: white,
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Listenelement für einen einzelnen Tag in der 7-Tage-Vorschau.
class _DayRow extends StatelessWidget {
  final String label;
  final String emoji;
  final String left;
  final String right;
  final VoidCallback? onTap;

  const _DayRow({
    super.key,
    required this.label,
    required this.emoji,
    required this.left,
    required this.right,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    const textStyle = TextStyle(
      color: white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // Verknüpft die Klick-Aktion für die Detailseite
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(label, style: textStyle),
              ),
              const SizedBox(width: 28),
              SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 52,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(left, style: textStyle),
                ),
              ),
              const SizedBox(
                width: 26,
                child: Center(
                  child: Text('/', style: textStyle),
                ),
              ),
              SizedBox(
                width: 52,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(right, style: textStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ein primärer Button im Pillen-Design.
class _PrimaryPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryPillButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const pill = Color(0xFF2B4544);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: pill,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// Konvertiert Wasserstand von Metern in Zentimeter.
String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
}

/// Ermittelt das Wochentag-Label oder "Heute" für das gegebene Datum.
String _getWeekdayLabel(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Heute';
  }

  const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return days[date.weekday - 1];
}

/// Ermittelt ein passendes Icon basierend auf der Temperatur.
IconData _getIconForTemp(double temp) {
  if (temp > 15) return Icons.wb_sunny;
  if (temp > 5) return Icons.cloud;
  return Icons.ac_unit;
}

/// Mittelt das passende Wetter-Emoji anhand des Codes und ob es Tag oder Nacht ist.
String _weatherEmojiFromCode(int? code, bool isDay) {
  if (code == null) return "❔";

  // Nacht-Overrides für Wetterzustände
  if (!isDay) {
    if (code == 0 || code == 1) return "🌙";
    if (code == 2 || code == 3) return "☁️";
    if (code >= 61 && code <= 67) return "🌧️";
    if (code >= 71 && code <= 77) return "🌨️";
    if (code >= 95) return "⛈️";
  }

  // Standard Tag-Mapping
  const iconMap = {
    0: "☀️",
    1: "🌤️",
    2: "⛅",
    3: "☁️",
    45: "🌫️",
    48: "🌫️",
    51: "🌦️",
    53: "🌦️",
    55: "🌦️",
    56: "🌧️",
    57: "🌧️",
    61: "🌧️",
    63: "🌧️",
    65: "🌧️",
    66: "🌧️",
    67: "🌧️",
    71: "🌨️",
    73: "🌨️",
    75: "🌨️",
    77: "❄️",
    80: "🌦️",
    81: "🌦️",
    82: "🌧️",
    85: "🌨️",
    86: "🌨️",
    95: "⛈️",
    96: "⛈️",
    99: "⛈️",
  };
  return iconMap[code] ?? "❔";
}