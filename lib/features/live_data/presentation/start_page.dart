import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';
import '../presentation/forecast_detail_page.dart';

class start_page extends ConsumerStatefulWidget {
  const start_page({super.key});

  @override
  ConsumerState<start_page> createState() => DashboardPageState();
}

class DashboardPageState extends ConsumerState<start_page> {
  @override
  void initState() {
    super.initState();
    // lädt beim Öffnen (wie bei Joni)
    Future.microtask(() => ref.read(liveDataNotifierProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);

    // Farben wie im Figma (ungefähr)
    const bg = Color(0xFF2B4544); // dunkles Grün/Teal
    const tile = Color(0xFF5E8886); // Kachel-Farbe
    const tileDark = Color(0xFF4F7876); // etwas dunkler
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
        //Button:
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Builder(
            builder: (_) {
              if (state.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

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

              if (state.stationData == null) {
                return Center(
                  child: _PrimaryPillButton(
                    text: 'Daten laden',
                    onPressed: () =>
                        ref.read(liveDataNotifierProvider.notifier).load(),
                  ),
                );
              }

              final station = state.stationData!;
              final forecast = state.forecast ?? <ForecastDto>[];
              debugPrint('FORECAST count: ${forecast.length}');
              if (forecast.isNotEmpty) {
                debugPrint('FORECAST first: ${forecast.first.date}');
                debugPrint('FORECAST last : ${forecast.last.date}');
              }

              final now = DateTime.now();

              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));
              // Nächste Stunden ab jetzt (egal ob Tag wechselt – viel robuster)
              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(24)
                  .toList();

              // Logik - Vorhersage nächste 7 Tage täglich min/max
              // 1. Gruppierung der vorhandenen Daten nach Tagen
              final Map<String, List<ForecastDto>> groupedByDay = {};
              for (var f in forecast) {
                final dayKey = "${f.date.year}-${f.date.month}-${f.date.day}";
                groupedByDay.putIfAbsent(dayKey, () => []).add(f);
              }

              // 2. Fixierte 7-Tage-Reihenfolge generieren (Beginnend mit Heute)
              final List<String> potentialDayKeys = List.generate(7, (index) {
                final date = DateTime.now().add(Duration(days: index));
                return "${date.year}-${date.month}-${date.day}";
              });

              // 3. Nur die Keys behalten, die auch wirklich Daten vom Modell erhalten haben
              // Das verhindert den "unexpected null value" Fehler bei Modellen mit kurzer Laufzeit
              final dayKeys = potentialDayKeys.where((key) => groupedByDay.containsKey(key)).toList();

              // Falls gar keine Vorhersage-Daten da sind, optional eine Info anzeigen
              if (dayKeys.isEmpty) {
                return const Center(child: Text("Keine Vorhersagedaten für dieses Modell verfügbar", style: TextStyle(color: Colors.white)));
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Top: 4 KPI-Kacheln (wie Var 3) ---
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
                            // Wind kommt vom Wettermodell (Forecast)
                            value: forecast.isNotEmpty
                                ? (forecast.first.windSpeed?.toStringAsFixed(1) ?? '--')
                                : '--',
                            unit: 'km/h',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // --- Forecast: nächste Stunden (live) horizontal scrollbar ---
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 130, // gleiche Höhe wie KPI-Kacheln
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(), // oder ClampingScrollPhysics()
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

                    // --- Unten: große „7-Tage“-Kachel (Platzhalter-Design) ---
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

                                // 2. Den am häufigsten vorkommenden Code finden (Modalwert)
                                final Map<int, int> occurrences = {};
                                for (var code in dailyCodes) {
                                  occurrences[code] = (occurrences[code] ?? 0) + 1;
                                }

                                // Den Code mit der höchsten Anzahl ermitteln
                                final mostFrequentCode = occurrences.entries
                                    .reduce((a, b) => a.value > b.value ? a : b)
                                    .key;

                                // 3. Temperaturen für Min/Max (bleibt gleich)
                                double minT = dayData.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
                                double maxT = dayData.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);

                                return _DayRow(
                                  label: _getWeekdayLabel(dayData.first.date),
                                  emoji: _weatherEmojiFromCode(mostFrequentCode, true),
                                  left: '${minT.round()}°',
                                  right: '${maxT.round()}°',
                                  // --- HIER DIE NEUE AKTION EINFÜGEN ---
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
          // ICON – perfekt zentriert
          Icon(icon, color: white, size: 22),

          const SizedBox(height: 8),

          // VALUE – skaliert automatisch bei großen Zahlen
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

          // UNIT – ebenfalls overflow-sicher
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
      height: 130, // gleiche Höhe wie KPI-Kacheln
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Zeit
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: white,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),

            const SizedBox(height: 6),

            // Emoji
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

            // Niederschlag
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

class _DayRow extends StatelessWidget {
  final String label;
  final String emoji;
  final String left;
  final String right;
  final VoidCallback? onTap; // <-- 1. Neues Feld hinzufügen

  const _DayRow({
    super.key,
    required this.label,
    required this.emoji,
    required this.left,
    required this.right,
    this.onTap, // <-- 2. Im Konstruktor hinzufügen
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;

    const textStyle = TextStyle(
      color: white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    // 3. Das Padding mit Material und InkWell umschließen
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap, // <-- 4. Klick-Aktion verknüpfen
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

/// ---- Helpers: Einheiten passend zu deinem Figma ----
/// Du hast im Figma bei Pegel "cm", aber dein DTO ist vermutlich in "m".
String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
}

// 7 Tage vorhersage
String _getWeekdayLabel(DateTime date) {
  final now = DateTime.now();
  // Prüfen, ob das Datum heute ist (Jahr, Monat und Tag gleich)
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Heute';
  }

  // Deutsche Wochentage (Index 1 = Montag, ..., 7 = Sonntag)
  const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return days[date.weekday - 1];
}

IconData _getIconForTemp(double temp) {
  if (temp > 15) return Icons.wb_sunny;
  if (temp > 5) return Icons.cloud;
  return Icons.ac_unit; // Kalt/Schnee
}

String _weatherEmojiFromCode(int? code, bool isDay) {
  if (code == null) return "❔";

    // Nacht-Overrides
  if (!isDay) {
    if (code == 0 || code == 1) return "🌙";
    if (code == 2 || code == 3) return "☁️";
    if (code >= 61 && code <= 67) return "🌧️";
    if (code >= 71 && code <= 77) return "🌨️";
    if (code >= 95) return "⛈️";
  }

    // Tag (dein bisheriges Mapping)
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