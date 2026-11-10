import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import 'common.dart';

class MeasurementHistoryScreen extends StatefulWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  State<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState extends State<MeasurementHistoryScreen> {
  static const _primary = Color(0xFF00777C);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF3E5658);
  int _days = 7;
  late final DateTime _today;
  List<VitalReading> _records = const [];
  int _total = 0;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _load();
  }

  /// Readings measured since the start of the chosen window, newest first.
  Future<void> _load() async {
    final days = _days;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await Api.instance.health.history(
        from: DateTime(_today.year, _today.month, _today.day - days + 1),
      );
      if (!mounted || days != _days) return;
      setState(() {
        _records = page.readings;
        _total = page.total;
      });
    } catch (e) {
      if (mounted && days == _days) setState(() => _error = e);
    } finally {
      if (mounted && days == _days) setState(() => _loading = false);
    }
  }

  String _values(VitalReading record) => [
    'SpO₂ ${record.spo2 == null ? '--' : decimal(record.spo2!)}%',
    'Nhịp tim ${record.heartRate ?? '--'} bpm',
    record.bodyTemperature != null
        ? 'Cơ thể ${decimal(record.bodyTemperature!)}°C'
        : 'Da ${record.skinTemperature == null ? '--' : decimal(record.skinTemperature!)}°C',
  ].join(' · ');

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
    final records = _records;
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
                        onSelectionChanged: (selection) {
                          setState(() => _days = selection.single);
                          _load();
                        },
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
                            BorderSide(color: Color(0xFFA9C1BE)),
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
                              _loading ? 'Đang tải...' : '$_total lần đo',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                          if (!_loading && _total > records.length)
                            Flexible(
                              child: Text(
                                'Hiển thị ${records.length} lần mới nhất',
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_loading && records.isEmpty) const LoadingBlock(),
                      if (_error != null)
                        ErrorBlock(error: _error!, onRetry: _load),
                      if (!_loading && _error == null && records.isEmpty)
                        const EmptyBlock(
                          icon: Icons.history_rounded,
                          message: 'Chưa có lần đo nào trong khoảng này.',
                        ),
                      for (final record in records)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFBDD3CE),
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
                                        _label(record.measuredAt),
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
                                  _values(record),
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
