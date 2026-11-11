import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';
import 'measurement_history_screen.dart';

/// Daily averages of one reading over 7 or 30 days (`/my_vital_signs/trend`).

class HealthTrendsScreen extends StatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  static const _ink = Color(0xFF164E50);
  static const _teal = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);
  static const _labels = ['SpO₂', 'Nhịp tim', 'Nhiệt độ'];
  static const _units = ['%', 'bpm', '°C'];
  static const _metrics = [
    VitalMetric.spo2,
    VitalMetric.heartRate,
    VitalMetric.skinTemperature,
  ];
  int _metric = 0;
  int _days = 7;
  int? _selected;
  VitalTrend? _trend;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    final days = _days;
    try {
      final now = DateTime.now();
      final trend = await Api.instance.health.trend(
        from: DateUtils.dateOnly(now).subtract(Duration(days: days - 1)),
        to: now,
      );
      if (mounted && days == _days) setState(() => _trend = trend);
    } catch (e) {
      if (mounted && days == _days) setState(() => _error = e);
    } finally {
      if (mounted && days == _days) setState(() => _loading = false);
    }
  }

  /// Body temperature when the band sent it, skin temperature otherwise.
  List<(DateTime, double)> get _bodySeries => [
    for (final point in _trend?.points ?? const <TrendPoint>[])
      if (point.bodyTemperatureAvg != null)
        (point.at, point.bodyTemperatureAvg!),
  ];
  bool get _body => _metric == 2 && _bodySeries.isNotEmpty;
  List<(DateTime, double)> get _series =>
      _body ? _bodySeries : _trend?.series(_metrics[_metric]) ?? const [];
  String get _label => _metric != 2
      ? _labels[_metric]
      : _body
      ? 'Nhiệt độ cơ thể'
      : 'Nhiệt độ da';
  String _number(double value) => value
      .toStringAsFixed(_metric == 2 || value != value.roundToDouble() ? 1 : 0)
      .replaceAll('.', ',');
  String _date(int index) => dayMonth(_series[index].$1);

  Widget _selector(
    List<String> labels,
    int selected,
    ValueChanged<int> onChanged,
  ) => SegmentedButton<int>(
    segments: List.generate(
      labels.length,
      (i) => ButtonSegment(
        value: i,
        label: Text(labels[i], textAlign: TextAlign.center),
      ),
    ),
    selected: {selected},
    showSelectedIcon: false,
    onSelectionChanged: (values) => onChanged(values.single),
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? _teal : Colors.white,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : _ink,
      ),
      side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFA9C1BE))),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFBDD3CE)),
    ),
    child: child,
  );

  Widget _chart(List<double> values) {
    if (_loading) return const SizedBox(height: 190, child: LoadingBlock());
    if (_error != null) return ErrorBlock(error: _error!, onRetry: _load);
    if (values.length < 2) {
      return const SizedBox(
        height: 190,
        child: Center(
          child: Text(
            'Chưa đủ dữ liệu trong khoảng thời gian này.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        void select(Offset position) {
          final index =
              ((position.dx - 38) /
                      (constraints.maxWidth - 46) *
                      (values.length - 1))
                  .round()
                  .clamp(0, values.length - 1);
          setState(() => _selected = index);
        }

        return Semantics(
          label: 'Biểu đồ $_label, $_days ngày. Vuốt hoặc chạm để chọn ngày.',
          value: _selected == null
              ? null
              : '${_date(_selected!)}: ${_number(values[_selected!])} ${_units[_metric]}',
          onIncrease: () => setState(
            () =>
                _selected = ((_selected ?? 0) + 1).clamp(0, values.length - 1),
          ),
          onDecrease: () => setState(
            () => _selected = ((_selected ?? values.length - 1) - 1).clamp(
              0,
              values.length - 1,
            ),
          ),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => select(d.localPosition),
            onHorizontalDragUpdate: (d) => select(d.localPosition),
            child: SizedBox(
              height: 190,
              child: CustomPaint(
                painter: _TrendPainter(values, _metric, _selected),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final series = _series;
    final values = [for (final point in series) point.$2];
    final average = values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFF3EF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Xu hướng sức khỏe',
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
                    _selector(
                      _labels,
                      _metric,
                      (value) => setState(() {
                        _metric = value;
                        _selected = null;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _selector(['7 ngày', '30 ngày'], _days == 7 ? 0 : 1, (
                      value,
                    ) {
                      setState(() {
                        _days = value == 0 ? 7 : 30;
                        _selected = null;
                      });
                      _load();
                    }),
                    const SizedBox(height: 20),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '$_label (${_units[_metric]}) · $_days ngày gần đây',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Trung bình mỗi ngày có đo',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                          const SizedBox(height: 22),
                          _chart(values),
                          if (values.length >= 2) ...[
                            const SizedBox(height: 12),
                            // A third of the width each, so a long date wraps instead of
                            // pushing the row past a narrow screen.
                            Row(
                              children: [
                                for (final (text, align) in [
                                  (_date(0), TextAlign.start),
                                  (_date(values.length ~/ 2), TextAlign.center),
                                  (relativeDay(series.last.$1), TextAlign.end),
                                ])
                                  Expanded(
                                    child: Text(
                                      text,
                                      textAlign: align,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (_selected != null &&
                              _selected! < values.length) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${_date(_selected!)} · $_label: ${_number(values[_selected!])} ${_units[_metric]}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _teal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xu hướng gần đây',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            average == null
                                ? 'Chưa có lần đo nào trong $_days ngày gần đây.'
                                : 'Mới nhất: ${_number(values.last)} ${_units[_metric]} · Trung bình: ${_number(average)} ${_units[_metric]}',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${values.length} ngày có đo trong $_days ngày gần đây.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chạm vào điểm trên biểu đồ để xem ngày đo và giá trị.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MeasurementHistoryScreen(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _teal,
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(color: Color(0xFFA9C1BE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Xem lịch sử',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _TrendPainter extends CustomPainter {
  const _TrendPainter(this.values, this.metric, this.selected);
  final List<double> values;
  final int metric;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    // The usual band of each reading, widened when the data leaves it.
    final min = math.min(
      [96.0, 68.0, 33.0][metric],
      values.reduce(math.min).floorToDouble(),
    );
    final max = math.max(
      [100.0, 80.0, 33.8][metric],
      values.reduce(math.max).ceilToDouble(),
    );
    final height = size.height - 16;
    for (var i = 0; i < 3; i++) {
      final y = 8 + height * i / 2;
      canvas.drawLine(
        Offset(38, y),
        Offset(size.width, y),
        Paint()..color = const Color(0xFFE5EFEB),
      );
      final label = TextPainter(
        text: TextSpan(
          text: (max - (max - min) * i / 2)
              .toStringAsFixed(metric == 2 ? 1 : 0)
              .replaceAll('.', ','),
          style: const TextStyle(fontSize: 10, color: Color(0xFF3E5658)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final points = List.generate(
      values.length,
      (i) => Offset(
        38 + (size.width - 46) * i / (values.length - 1),
        8 + (max - values[i]) / (max - min) * height,
      ),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(38, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x33008C91), Color(0x00008C91)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = const Color(0xFF00777C)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF00777C));
    }
    if (selected != null) {
      final point = points[selected!];
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, size.height),
        Paint()..color = const Color(0x66008C91),
      );
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF00777C));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.metric != metric ||
      oldDelegate.selected != selected ||
      oldDelegate.values != values;
}
