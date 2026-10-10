import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeasurementHistoryScreen extends StatefulWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  State<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState extends State<MeasurementHistoryScreen> {
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);
  int _days = 7;
  late final DateTime _today;
  late final List<({DateTime time, int spo2, int pulse, String temperature})>
  _records;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _records = [
      (
        time: _today.add(const Duration(hours: 9, minutes: 41)),
        spo2: 98,
        pulse: 72,
        temperature: '33,4',
      ),
      (
        time: _today.add(const Duration(hours: 8, minutes: 15)),
        spo2: 97,
        pulse: 75,
        temperature: '33,2',
      ),
      (
        time: DateTime(now.year, now.month, now.day - 1, 20, 10),
        spo2: 98,
        pulse: 74,
        temperature: '33,3',
      ),
      (
        time: DateTime(now.year, now.month, now.day - 4, 9),
        spo2: 97,
        pulse: 76,
        temperature: '33,5',
      ),
      (
        time: DateTime(now.year, now.month, now.day - 14, 8, 30),
        spo2: 98,
        pulse: 73,
        temperature: '33,4',
      ),
    ];
  }

  String _label(DateTime time) {
    final date = DateTime(time.year, time.month, time.day);
    final day = date == _today
        ? 'Hôm nay'
        : date == DateTime(_today.year, _today.month, _today.day - 1)
        ? 'Hôm qua'
        : '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}';
    return '$day · ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final start = DateTime(_today.year, _today.month, _today.day - _days + 1);
    final records = _records
        .where((record) => !record.time.isBefore(start))
        .toList();
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF6FBF9),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDFF3EF),
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Lịch sử đo',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDFF3EF), Color(0xFFEEF9F6), Color(0xFFF6FBF9)],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('Hôm nay')),
                          ButtonSegment(value: 7, label: Text('7 ngày')),
                          ButtonSegment(value: 30, label: Text('30 ngày')),
                        ],
                        selected: {_days},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) =>
                            setState(() => _days = selection.single),
                        style: ButtonStyle(
                          minimumSize: const WidgetStatePropertyAll(
                            Size(0, 48),
                          ),
                          backgroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? _primary
                                : Colors.white,
                          ),
                          foregroundColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Colors.white
                                : _ink,
                          ),
                          side: const WidgetStatePropertyAll(
                            BorderSide(color: Color(0xFFCCDADC)),
                          ),
                          textStyle: const WidgetStatePropertyAll(
                            TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${records.length} lần đo',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                          const Text(
                            'Dữ liệu mẫu',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final record in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE0ECE9),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.history_rounded,
                                      size: 20,
                                      color: _primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _label(record.time),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'SpO₂ ${record.spo2}% · Nhịp tim ${record.pulse} bpm · Da ${record.temperature}°C',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.6,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
