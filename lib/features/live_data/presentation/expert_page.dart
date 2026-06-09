import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fog_cast_app/features/live_data/data/dto/history_dto.dart';
import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class expert_page extends ConsumerStatefulWidget {
  const expert_page({super.key});

  @override
  ConsumerState<expert_page> createState() => _ExpertPageState();
}

class _ExpertPageState extends ConsumerState<expert_page> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool temperatur = true;
  bool luftfeuchtigkeit = true;
  bool niederschlag = true;
  bool wolkendichte = false;
  bool gewitter = false;
  bool wasserlevel = true;

  List<HistoryDto> waterLevelHistory = [];
  bool isLoadingHistory = false;
  bool _historyLoadTriggered = false;

  String selectedModel = 'icon_d2';
  String selectedPage = 'Standard';

  Future<void> loadWaterLevelHistory() async {
    setState(() => isLoadingHistory = true);

    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 31));

    try {
      final history = await ref.read(historyRepositoryProvider).getArchiveHistory(
        parameter: 'water-level',
        start: start,
        stop: now,
        stationId: 1,
        period: 'd',
      );

      setState(() {
        waterLevelHistory = history;
        isLoadingHistory = false;
      });
    } catch (_) {
      setState(() => isLoadingHistory = false);
    }
  }

  // Lädt die gespeicherten Einstellungen
  Future<void> _loadMenuPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Lädt die vom Nutzer selbst definierte "Standard"-Ansicht
      temperatur = prefs.getBool('expert_temperatur') ?? true;
      luftfeuchtigkeit = prefs.getBool('expert_luftfeuchtigkeit') ?? true;
      niederschlag = prefs.getBool('expert_niederschlag') ?? true;
      wasserlevel = prefs.getBool('expert_wasserlevel') ?? true;
      wolkendichte = prefs.getBool('expert_wolkendichte') ?? false;
      gewitter = prefs.getBool('expert_gewitter') ?? false;

      selectedModel = prefs.getString('expert_selectedModel') ?? 'icon_d2';
      // Wir lassen die Page standardmäßig auf "Standard", da dies nun die eigene Ansicht ist
      selectedPage = prefs.getString('expert_selectedPage') ?? 'Standard';
    });
  }

  // Speichert alle aktuellen Werte direkt ab
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('expert_temperatur', temperatur);
    await prefs.setBool('expert_luftfeuchtigkeit', luftfeuchtigkeit);
    await prefs.setBool('expert_niederschlag', niederschlag);
    await prefs.setBool('expert_wasserlevel', wasserlevel);
    await prefs.setBool('expert_wolkendichte', wolkendichte);
    await prefs.setBool('expert_gewitter', gewitter);

    await prefs.setString('expert_selectedModel', selectedModel);
    await prefs.setString('expert_selectedPage', selectedPage);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _loadMenuPreferences();
      // Lädt die Daten direkt mit der gespeicherten Modell-ID (z.B. 'icon_d2')
      ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: selectedModel);
      await loadWaterLevelHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(expertLiveDataNotifierProvider);

    if (!_historyLoadTriggered) {
      _historyLoadTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await loadWaterLevelHistory();
      });
    }

    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const tileDark = Color(0xFF4F7876);
    const white = Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: ExpertMenuDrawer(
        temperatur: temperatur,
        luftfeuchtigkeit: luftfeuchtigkeit,
        niederschlag: niederschlag,
        wolkendichte: wolkendichte,
        gewitter: gewitter,
        wasserlevel: wasserlevel,
        selectedModel: selectedModel,
        selectedPage: selectedPage,
        onWasserlevelChanged: (v) => setState(() => wasserlevel = v),
        onTemperaturChanged: (v) => setState(() => temperatur = v),
        onLuftfeuchtigkeitChanged: (v) => setState(() => luftfeuchtigkeit = v),
        onNiederschlagChanged: (v) => setState(() => niederschlag = v),
        onWolkendichteChanged: (v) => setState(() => wolkendichte = v),
        onGewitterChanged: (v) => setState(() => gewitter = v),
        onModelChanged: (v) async {
          setState(() => selectedModel = v);
          // Lädt die Daten für die Live-Vorschau im Hintergrund,
          // speichert das Modell aber noch NICHT dauerhaft ab!
          ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: v);
        },
        // HIER DIE KORREKTUR: Funktion als 'async' deklarieren
        onPageChanged: (v) async {
          setState(() {
            selectedPage = v;
          });

          if (v == 'Wind') {
            setState(() {
              temperatur = false;
              luftfeuchtigkeit = false;
              niederschlag = false;
              wasserlevel = false;
              wolkendichte = true;
              gewitter = false;
            });
          } else if (v == 'Niederschlag') {
            setState(() {
              temperatur = false;
              luftfeuchtigkeit = true;
              niederschlag = true;
              wasserlevel = true;
              wolkendichte = false;
              gewitter = true;
            });
          } else if (v == 'Standard') {
            // Lädt die echten, gespeicherten Checkboxen UND das gespeicherte Modell
            await _loadMenuPreferences();

            // Wichtig: Die Daten des alten, gespeicherten Modells wieder laden!
            ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: selectedModel);
          }
        },
        onSave: () async {
          await _savePreferences();
        },
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
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
                              ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: selectedModel),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state.modelData == null) {
                return Center(
                  child: _PrimaryPillButton(
                    text: 'Modelldaten laden',
                    onPressed: () =>
                        ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: selectedModel),
                  ),
                );
              }

              final modelData = state.modelData!;
              final forecast = state.forecast ?? <ForecastDto>[];

              final now = DateTime.now();
              final sorted = [...forecast]..sort((a, b) => a.date.compareTo(b.date));

              final hours = sorted
                  .where((f) => f.date.isAfter(now.subtract(const Duration(minutes: 1))))
                  .take(24)
                  .toList();

              final currentForecast = hours.isNotEmpty ? hours.first : null;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // NEU: SingleChildScrollView erlaubt horizontales Scrollen für alle 5 Kacheln
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // 1. Kachel: Temperatur aus dem Modell
                          SizedBox(
                            width: 90,
                            child: _MetricTile(
                              color: tile,
                              icon: Icons.thermostat,
                              value: currentForecast?.temperature != null
                                  ? currentForecast!.temperature.toStringAsFixed(0)
                                  : '--',
                              unit: '°',
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Kachel: Luftfeuchtigkeit aus dem Modell
                          SizedBox(
                            width: 90,
                            child: _MetricTile(
                              color: tile,
                              icon: Icons.water_drop,
                              value: currentForecast?.humidity != null
                                  ? currentForecast!.humidity!.toStringAsFixed(0)
                                  : '--',
                              unit: '%',
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 3. Kachel: Luftdruck aus dem Modell
                          SizedBox(
                            width: 90,
                            child: _MetricTile(
                              color: tile,
                              icon: Icons.compress,
                              value: currentForecast?.airPressure != null
                                  ? currentForecast!.airPressure!.toStringAsFixed(0)
                                  : '--',
                              unit: 'hPa',
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 4. Kachel: Windgeschwindigkeit aus dem Modell
                          SizedBox(
                            width: 90,
                            child: _MetricTile(
                              color: tile,
                              icon: Icons.air,
                              value: currentForecast?.windSpeed != null
                                  ? currentForecast!.windSpeed!.toStringAsFixed(1)
                                  : '--',
                              unit: 'm/s',
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 5. Kachel: Wasserlevel (Modell mit automatischem Stations-Fallback)
                          SizedBox(
                            width: 90,
                            child: _MetricTile(
                              color: tile,
                              icon: Icons.waves,
                              value: () {
                                // Versuch, das Wasserlevel dynamisch aus dem Modell zu lesen
                                dynamic modelWaterLevel;
                                try {
                                  modelWaterLevel = (currentForecast as dynamic).waterLevel;
                                } catch (_) {
                                  modelWaterLevel = null;
                                }

                                if (modelWaterLevel != null && modelWaterLevel is num) {
                                  return _formatWaterLevelForFigma(modelWaterLevel.toDouble());
                                }

                                // Fallback auf die realen Stations-Messwerte, wenn das Modell nichts liefert
                                if (modelData != null) {
                                  return _formatWaterLevelForFigma(modelData.waterLevel);
                                }

                                return '--';
                              }(),
                              unit: 'cm',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (hours.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ListView.separated(
                          primary: false,
                          physics: const BouncingScrollPhysics(),
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          padding: EdgeInsets.zero,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            return _ExpertHourForecastTile(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (temperatur) ...[
                          _ExpertGraphCard(
                            title: 'Temperatur',
                            child: _TemperatureBarChart(data: forecast),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (luftfeuchtigkeit) ...[
                          _ExpertGraphCard(
                            title: 'Luftfeuchtigkeit',
                            child: _HumidityBarChart(data: forecast),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (niederschlag) ...[
                          _ExpertGraphCard(
                            title: 'Niederschlag',
                            child: _PrecipitationBarChart(data: forecast),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (wasserlevel) ...[
                          _ExpertGraphCard(
                            title: 'Wasserlevel',
                            child: isLoadingHistory
                                ? const Center(
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                                : _ExpertWaterLevelHistoryChart(
                              data: waterLevelHistory
                                  .map((e) => _WaterLevelPoint(
                                date: e.date,
                                valueCm: e.value,
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (wolkendichte) ...[
                          _ExpertGraphCard(
                            title: 'Wolkendichte',
                            child: _CloudCoverChart(data: forecast),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (gewitter) ...[
                          _ExpertGraphCard(
                            title: 'Gewitter',
                            child: _ThunderstormBarChart(data: forecast),
                          ),
                          const SizedBox(height: 14),
                        ],
                        _PrimaryPillButton(
                          text: 'Aktualisieren',
                          onPressed: () =>
                              ref.read(expertLiveDataNotifierProvider.notifier).load(modelId: selectedModel),
                        ),
                      ],
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: white, size: 22),
          const SizedBox(height: 8),
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

class _ExpertLineChart extends StatelessWidget {
  final List<ForecastDto> data;
  final String unitY;
  final String unitX;
  final double? Function(ForecastDto f) valueSelector;
  final bool curved;

  const _ExpertLineChart({
    required this.data,
    required this.unitY,
    required this.unitX,
    required this.valueSelector,
    this.curved = true,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;

    final now = DateTime.now();
    // Start ist die aktuelle Stunde (0 Minuten/Sekunden für sauberen Chart-Beginn)
    final chartStart = DateTime(now.year, now.month, now.day, now.hour);
    final chartEnd = chartStart.add(const Duration(hours: 24));

    // Filtere Daten für die nächsten 24 Stunden
    final filteredData = data
        .where((f) => !f.date.isBefore(chartStart) && f.date.isBefore(chartEnd))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final spots = <FlSpot>[];
    for (final f in filteredData) {
      // X-Wert ist die Differenz in Stunden zum Startzeitpunkt (0.0 bis 24.0)
      final x = f.date.difference(chartStart).inMinutes / 60.0;
      final y = valueSelector(f);

      if (y != null && y.isFinite) {
        spots.add(FlSpot(x, y));
      }
    }

    if (spots.length < 2) {
      return const Center(
        child: Text(
          'Keine Verlaufsdaten verfügbar',
          style: TextStyle(color: white, fontSize: 14),
        ),
      );
    }

    // Y-Achsen Skalierung
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    double padding = (maxY - minY) * 0.15;
    if (padding == 0) padding = 1.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 24, // Fixiert auf 24 Stunden
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(color: white.withOpacity(0.1), strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: white.withOpacity(0.1), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Colors.black87,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(1)} cm',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 6, // Zeige alle 6 Stunden eine Beschriftung
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value > 24) return const SizedBox.shrink();
                  // Berechne die tatsächliche Uhrzeit für das Label
                  final labelTime = chartStart.add(Duration(hours: value.toInt()));
                  return Text(
                    '${labelTime.hour}:00',
                    style: const TextStyle(color: darkText, fontSize: 10),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: darkText, fontSize: 10),
                ),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: curved,
              barWidth: 3,
              color: white,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: white.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _intervalForY(double range) {
  if (range <= 5) return 1;
  if (range <= 10) return 2;
  if (range <= 20) return 5;
  if (range <= 50) return 10;
  return 20;
}

class _ExpertGraphCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ExpertGraphCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const chartBg = Color(0xFF274847);
    const white = Colors.white;

    return _RoundedTile(
      color: tile,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: chartBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpertHourForecastTile extends StatelessWidget {
  final Color color;
  final ForecastDto dto;

  const _ExpertHourForecastTile({
    required this.color,
    required this.dto,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final hour = dto.date.hour;
    final windSpeed = dto.windSpeed ?? 0.0;
    final direction = dto.windDirection ?? 0.0;

    return Container(
      width: (MediaQuery.of(context).size.width - 36 - 36) / 4,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${hour.toString().padLeft(2, '0')}:00',
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Transform.rotate(
            angle: direction * 3.1415926535897932 / 180,
            child: const Icon(
              Icons.navigation,
              color: white,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            windSpeed.toStringAsFixed(0),
            style: const TextStyle(
              color: white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'km/h',
            style: TextStyle(
              color: white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertWaterLevelHistoryChart extends StatelessWidget {
  final List<_WaterLevelPoint> data;

  const _ExpertWaterLevelHistoryChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;

    if (data.length < 2) {
      return const Center(
        child: Text(
          'Keine historischen Wasserlevel-Daten verfügbar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 16,
          ),
        ),
      );
    }

    final sorted = [...data]..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 30));
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final filtered = sorted
        .where((p) => !p.date.isBefore(startDate) && !p.date.isAfter(endDate))
        .toList();

    if (filtered.length < 2) {
      return const Center(
        child: Text(
          'Keine historischen Wasserlevel-Daten verfügbar',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: white,
            fontSize: 16,
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      spots.add(FlSpot(i.toDouble(), filtered[i].valueCm));
    }

    double minY = filtered.first.valueCm;
    double maxY = filtered.first.valueCm;

    for (final p in filtered) {
      if (p.valueCm < minY) minY = p.valueCm;
      if (p.valueCm > maxY) maxY = p.valueCm;
    }

    minY = minY.roundToDouble();
    maxY = maxY.ceilToDouble();

    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      child: Stack(
        children: [
          LineChart(
            LineChartData(
              minX: 0,
              maxX: (filtered.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                drawHorizontalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => FlLine(
                  color: white.withOpacity(0.18),
                  strokeWidth: 1,
                ),
              ),
        borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (touchedSpot) => Colors.black87,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} cm',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: _intervalForY(maxY - minY),
                    getTitlesWidget: (value, meta) {
                      if (value == maxY) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      if (index % 5 != 0) {
                        return const SizedBox.shrink();
                      }
                      final d = filtered[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${d.day}.${d.month}.',
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 3.5,
                  color: white,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 4,
            top: 6,
            child: Text(
              'cm',
              style: TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Positioned(
            right: 8,
            bottom: 2,
            child: Text(
              'Datum',
              style: TextStyle(
                color: darkText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatWaterLevelForFigma(double waterLevelMeters) {
  final cm = waterLevelMeters * 100.0;
  return cm.toStringAsFixed(0);
}

class ExpertMenuDrawer extends StatelessWidget {
  final bool temperatur;
  final bool luftfeuchtigkeit;
  final bool niederschlag;
  final bool wolkendichte;
  final bool gewitter;
  final bool wasserlevel;
  final String selectedModel;
  final String selectedPage;
  final ValueChanged<bool> onTemperaturChanged;
  final ValueChanged<bool> onLuftfeuchtigkeitChanged;
  final ValueChanged<bool> onNiederschlagChanged;
  final ValueChanged<bool> onWolkendichteChanged;
  final ValueChanged<bool> onGewitterChanged;
  final ValueChanged<bool> onWasserlevelChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onPageChanged;
  final Future<void> Function() onSave; // NEU: Typdefinition für die Speicherfunktion

  const ExpertMenuDrawer({
    super.key,
    required this.temperatur,
    required this.luftfeuchtigkeit,
    required this.niederschlag,
    required this.wolkendichte,
    required this.gewitter,
    required this.wasserlevel,
    required this.selectedModel,
    required this.selectedPage,
    required this.onTemperaturChanged,
    required this.onLuftfeuchtigkeitChanged,
    required this.onNiederschlagChanged,
    required this.onWolkendichteChanged,
    required this.onGewitterChanged,
    required this.onWasserlevelChanged,
    required this.onModelChanged,
    required this.onPageChanged,
    required this.onSave, // NEU: Im Konstruktor fordern
  });

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF2B4544);
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FOGCAST',
                      style: TextStyle(
                        color: white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                        color: white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'Parameterauswahl',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _MenuCheckRow(
                  label: 'Temperatur',
                  value: temperatur,
                  onChanged: onTemperaturChanged,
                ),
                _MenuCheckRow(
                  label: 'Luftfeuchtigkeit',
                  value: luftfeuchtigkeit,
                  onChanged: onLuftfeuchtigkeitChanged,
                ),
                _MenuCheckRow(
                  label: 'Niederschlag',
                  value: niederschlag,
                  onChanged: onNiederschlagChanged,
                ),
                _MenuCheckRow(
                  label: 'Wasserlevel',
                  value: wasserlevel,
                  onChanged: onWasserlevelChanged,
                ),
                _MenuCheckRow(
                  label: 'Wolkendichte',
                  value: wolkendichte,
                  onChanged: onWolkendichteChanged,
                ),
                _MenuCheckRow(
                  label: 'Gewitter',
                  value: gewitter,
                  onChanged: onGewitterChanged,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      // 1. Führt das übergebene '_savePreferences()' aus der Hauptseite aus
                      await onSave();

                      // 2. Danach das Menü schließen
                      Navigator.of(context).pop();

                      // Visueller Hinweis für den Nutzer auf dem Bildschirm
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Standard-Ansicht erfolgreich gespeichert!')),
                      );
                    },
                    child: const Text('Speichern'),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Modellauswahl',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuDropdown(
                  value: selectedModel,
                  items: const [
                    'cma_grapes_global',
                    'dmi_harmonie_arome_europe',
                    'dmi_seamless',
                    'ecmwf_ifs025',
                    'gem_global',
                    'gem_seamless',
                    'gfs_global',
                    'gfs_seamless',
                    'icon_d2',
                    'icon_eu',
                    'icon_global',
                    'icon_seamless',
                    'jma_gsm',
                    'jma_seamless',
                    'knmi_harmonie_arome_europe',
                    'knmi_seamless',
                    'meteofrance_arome_france',
                    'meteofrance_arome_france_hd',
                    'meteofrance_arpege_europe',
                    'meteofrance_arpege_world',
                    'meteofrance_seamless',
                    'meteoswiss_icon_ch1',
                    'meteoswiss_icon_ch2',
                    'meteoswiss_icon_seamless',
                    'metno_seamless',
                    'ukmo_global_deterministic_10km',
                    'ukmo_seamless',
                    'ukmo_uk_deterministic_2km'
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      onModelChanged(v);
                    }
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Deine Seiten',
                  style: TextStyle(
                    color: white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _MenuDropdown(
                  value: selectedPage,
                  items: const ['Standard', 'Wind', 'Niederschlag'],
                  onChanged: (v) {
                    if (v != null) {
                      onPageChanged(v);
                    }
                  },
                ),
                const SizedBox(height: 28),
                const Icon(Icons.swap_horiz, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuCheckRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MenuCheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          InkWell(
            onTap: () => onChanged(!value),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(12),
              ),
              child: value ? const Icon(Icons.check, color: white, size: 28) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _MenuDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const tile = Color(0xFF5E8886);
    const white = Colors.white;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tile,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: tile,
          icon: const Icon(Icons.keyboard_arrow_down, color: white),
          style: const TextStyle(
            color: white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
              .toList(),
          onChanged: onChanged,
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

class _WaterLevelPoint {
  final DateTime date;
  final double valueCm;

  const _WaterLevelPoint({
    required this.date,
    required this.valueCm,
  });
}

double _xIntervalForHistory(int count) {
  if (count <= 7) return 1;
  if (count <= 14) return 3;
  if (count <= 21) return 5;
  return 7;
}

class _CloudCoverChart extends StatelessWidget {
  final List<ForecastDto> data;

  const _CloudCoverChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;
    const chartHeight = 145.0;

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final items = data
        .where((f) => !f.date.isBefore(now) && !f.date.isAfter(end))
        .where((f) => f.cloudCover != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Keine Wolkendichte-Daten verfügbar',
          style: TextStyle(color: white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Y-Achse links
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('100%', style: TextStyle(color: darkText, fontSize: 11)),
                      Text('50%', style: TextStyle(color: darkText, fontSize: 11)),
                      Text('0%', style: TextStyle(color: darkText, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 24), // exakt gleiche Höhe wie X-Achse unten!
              ],
            ),
          ),

          const SizedBox(width: 6),

          // Scrollbarer Chartbereich
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: items.length * 36,
                height: 170,
                child: Column(
                  children: [
                    SizedBox(
                      height: 145,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items.map((f) {
                          final cover = (f.cloudCover ?? 0).clamp(0, 100);                          final height = cover == 0
                              ? 8.0
                              : 8.0 + (cover / 100) * (chartHeight - 8.0);

                          return SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message: '${cover.toStringAsFixed(1)} %',
                                preferBelow: false,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Container(
                                  width: 24,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: white.withOpacity(
                                      0.20 + (cover / 100) * 0.60,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 4),

                    SizedBox(
                      height: 18,
                      child: Row(
                        children: items.map((f) {
                          return SizedBox(
                            width: 36,
                            child: Text(
                              f.date.hour.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrecipitationBarChart extends StatelessWidget {
  final List<ForecastDto> data;

  const _PrecipitationBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;
    const chartHeight = 145.0;
    const xAxisHeight = 24.0;

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final items = data
        .where((f) => !f.date.isBefore(now) && !f.date.isAfter(end))
        .where((f) => f.precipitation != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Keine Niederschlagsdaten verfügbar',
          style: TextStyle(color: white),
        ),
      );
    }

    final maxValue = items
        .map((e) => e.precipitation ?? 0)
        .reduce((a, b) => a > b ? a : b);

    final axisMax = maxValue <= 1
        ? 1.0
        : maxValue <= 5
        ? 5.0
        : maxValue <= 10
        ? 10.0
        : maxValue.ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 38,
            height: chartHeight + xAxisHeight,
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${axisMax.toStringAsFixed(axisMax % 1 == 0 ? 0 : 1)} mm',
                        style: const TextStyle(color: darkText, fontSize: 10),
                      ),
                      Text(
                        '${(axisMax / 2).toStringAsFixed(axisMax >= 2 ? 0 : 1)}',
                        style: const TextStyle(color: darkText, fontSize: 10),
                      ),
                      const Text(
                        '0',
                        style: TextStyle(color: darkText, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: xAxisHeight),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: items.length * 36,
                height: chartHeight + xAxisHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items.map((f) {
                          final value = (f.precipitation ?? 0).clamp(0, axisMax).toDouble();
                          final normalized = (value / axisMax) * chartHeight;

                          final height = value == 0
                              ? 8.0
                              : normalized;
                          return SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message: '${value.toStringAsFixed(1)} mm',
                                preferBelow: false,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Container(
                                  width: 24,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: white.withOpacity(
                                      value == 0 ? 0.25 : 0.45 + (value / axisMax) * 0.45,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(
                      height: xAxisHeight,
                      child: Row(
                        children: items.map((f) {
                          return SizedBox(
                            width: 36,
                            child: Text(
                              f.date.hour.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemperatureBarChart extends StatelessWidget {
  final List<ForecastDto> data;

  const _TemperatureBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;
    const chartHeight = 145.0;
    const xAxisHeight = 24.0;

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final items = data
        .where((f) => !f.date.isBefore(now) && !f.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Keine Temperaturdaten verfügbar',
          style: TextStyle(color: white),
        ),
      );
    }

    double minValue = items.map((e) => e.temperature).reduce((a, b) => a < b ? a : b);
    double maxValue = items.map((e) => e.temperature).reduce((a, b) => a > b ? a : b);

    minValue = minValue.floorToDouble();
    maxValue = maxValue.ceilToDouble();

    if (minValue == maxValue) {
      minValue -= 1;
      maxValue += 1;
    }

    final range = maxValue - minValue;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 38,
            height: chartHeight + xAxisHeight,
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${maxValue.toStringAsFixed(0)}°', style: const TextStyle(color: darkText, fontSize: 10)),
                      Text('${((maxValue + minValue) / 2).toStringAsFixed(0)}', style: const TextStyle(color: darkText, fontSize: 10)),
                      Text('${minValue.toStringAsFixed(0)}', style: const TextStyle(color: darkText, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: xAxisHeight),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: items.length * 36,
                height: chartHeight + xAxisHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items.map((f) {
                          final value = f.temperature;
                          final normalized = ((value - minValue) / range).clamp(0.0, 1.0);
                          final height = 8.0 + normalized * (chartHeight - 8.0);

                          return SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: 24,
                                height: height,
                                decoration: BoxDecoration(
                                  color: white.withOpacity(0.25 + normalized * 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(
                      height: xAxisHeight,
                      child: Row(
                        children: items.map((f) {
                          return SizedBox(
                            width: 36,
                            child: Text(
                              f.date.hour.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HumidityBarChart extends StatelessWidget {
  final List<ForecastDto> data;

  const _HumidityBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;
    const chartHeight = 145.0;
    const xAxisHeight = 24.0;

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final items = data
        .where((f) => !f.date.isBefore(now) && !f.date.isAfter(end))
        .where((f) => f.humidity != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Keine Luftfeuchtigkeitsdaten verfügbar',
          style: TextStyle(color: white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 38,
            height: chartHeight + xAxisHeight,
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('100%', style: TextStyle(color: darkText, fontSize: 10)),
                      Text('50%', style: TextStyle(color: darkText, fontSize: 10)),
                      Text('0%', style: TextStyle(color: darkText, fontSize: 10)),
                    ],
                  ),
                ),
                const SizedBox(height: xAxisHeight),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: items.length * 36,
                height: chartHeight + xAxisHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items.map((f) {
                          final humidity = (f.humidity ?? 0).clamp(0, 100).toDouble();
                          final height = humidity == 0
                              ? 8.0
                              : 8.0 + (humidity / 100) * (chartHeight - 8.0);

                          return SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message: '${humidity.toStringAsFixed(1)} %',
                                preferBelow: false,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Container(
                                  width: 24,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: white.withOpacity(0.20 + (humidity / 100) * 0.60),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(
                      height: xAxisHeight,
                      child: Row(
                        children: items.map((f) {
                          return SizedBox(
                            width: 36,
                            child: Text(
                              f.date.hour.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThunderstormBarChart extends StatelessWidget {
  final List<ForecastDto> data;

  const _ThunderstormBarChart({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    const darkText = Colors.black87;
    const chartHeight = 145.0;
    const xAxisHeight = 24.0;

    final now = DateTime.now();
    final end = now.add(const Duration(hours: 48));

    final items = data
        .where((f) => !f.date.isBefore(now) && !f.date.isAfter(end))
        .where((f) => f.cape != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'Keine Gewitterdaten verfügbar',
          style: TextStyle(color: white),
        ),
      );
    }

    final maxValue = items
        .map((e) => e.cape ?? 0)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    final axisMax = maxValue <= 100
        ? 100.0
        : maxValue <= 500
        ? 500.0
        : maxValue <= 1000
        ? 1000.0
        : maxValue.ceilToDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 42,
            height: chartHeight + xAxisHeight,
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        axisMax.toStringAsFixed(0),
                        style: const TextStyle(color: darkText, fontSize: 10),
                      ),
                      Text(
                        (axisMax / 2).toStringAsFixed(0),
                        style: const TextStyle(color: darkText, fontSize: 10),
                      ),
                      const Text(
                        '0',
                        style: TextStyle(color: darkText, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: xAxisHeight),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: items.length * 36,
                height: chartHeight + xAxisHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items.map((f) {
                          final value = (f.cape ?? 0).clamp(0, axisMax).toDouble();
                          final normalized = value / axisMax;

                          final height = value == 0
                              ? 8.0
                              : 8.0 + normalized * (chartHeight - 8.0);

                          return SizedBox(
                            width: 36,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Tooltip(
                                message: '${value.toStringAsFixed(1)} J/kg',
                                preferBelow: false,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                child: Container(
                                  width: 24,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: white.withOpacity(
                                      value == 0
                                          ? 0.25
                                          : 0.35 + normalized * 0.55,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    SizedBox(
                      height: xAxisHeight,
                      child: Row(
                        children: items.map((f) {
                          return SizedBox(
                            width: 36,
                            child: Text(
                              f.date.hour.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}