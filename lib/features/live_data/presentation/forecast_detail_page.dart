import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/live_data_providers.dart';
import '../data/dto/forecast_dto.dart';

class ForecastDetailPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const ForecastDetailPage({super.key, required this.selectedDate});

  @override
  ConsumerState<ForecastDetailPage> createState() => _ForecastDetailPageState();
}

class _ForecastDetailPageState extends ConsumerState<ForecastDetailPage> {
  static const bg = Color(0xFF2B4544);
  static const tile = Color(0xFF5E8886);
  static const tileDark = Color(0xFF2F4F4F);
  static const white = Colors.white;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(liveDataNotifierProvider);
    final forecast = state.forecast ?? <ForecastDto>[];

    final targetDate = widget.selectedDate;
    final start = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0);
    final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59);

    final dayData = forecast
        .where((f) => !f.date.isBefore(start) && !f.date.isAfter(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final now = DateTime.now();
    final hourlyItems = dayData.where((f) {
      final isToday = targetDate.year == now.year &&
          targetDate.month == now.month &&
          targetDate.day == now.day;

      if (isToday) {
        return f.date.isAfter(now) || f.date.isAtSameMomentAs(now);
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: white),
        centerTitle: true,
        title: const Text(
          'FOGCAST',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: tileDark,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _formatGermanDate(targetDate),
                  style: const TextStyle(
                    color: white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Stündliche Vorschau',
              style: TextStyle(
                color: white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            if (hourlyItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Keine Vorhersagedaten für diesen Tag verfügbar',
                    style: TextStyle(color: white),
                  ),
                ),
              )
            else
              Column(
                children: hourlyItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HourlyVerticalTile(
                      item: item,
                      emoji: _weatherEmojiFromCode(item.weatherCode),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

String _formatGermanDate(DateTime d) {
  const w = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const m = [
    'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
  ];

  return '${w[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}. ${m[d.month - 1]} ${d.year}';
}

String _weatherEmojiFromCode(int? code) {
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
    71: "🌨️",
    73: "🌨️",
    75: "🌨️",
    77: "❄️",
    80: "🌦️",
    81: "🌦️",
    82: "🌧️",
    95: "⛈️",
    96: "⛈️",
    99: "⛈️",
  };

  if (code == null) return "❔";
  return iconMap[code] ?? "❔";
}

class _HourlyVerticalTile extends StatelessWidget {
  final ForecastDto item;
  final String emoji;

  const _HourlyVerticalTile({
    required this.item,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF5E8886),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 45,
            child: Text(
              "${item.date.hour.toString().padLeft(2, '0')}:00",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(
            width: 35,
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),

          SizedBox(
            width: 45,
            child: Text(
              "${item.temperature.round()}°",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Spacer(),

          _SmallWeatherInfo(
            icon: Icons.air,
            value: "${item.windSpeed?.toStringAsFixed(1) ?? '0'} m/s",
          ),

          const SizedBox(width: 12),

          _SmallWeatherInfo(
            icon: Icons.grain,
            value: "${item.precipitation?.toStringAsFixed(1) ?? '0'} mm",
          ),
        ],
      ),
    );
  }
}

class _SmallWeatherInfo extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallWeatherInfo({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}