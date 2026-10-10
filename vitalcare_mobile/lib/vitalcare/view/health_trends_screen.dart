import 'package:flutter/material.dart';
import 'measurement_history_screen.dart';

class HealthTrendsScreen extends StatefulWidget {
  const HealthTrendsScreen({super.key});

  @override
  State<HealthTrendsScreen> createState() => _HealthTrendsScreenState();
}

class _HealthTrendsScreenState extends State<HealthTrendsScreen> {
  static const _ink = Color(0xFF164E50);
  static const _teal = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _labels = ['SpO₂', 'Nhịp tim', 'Nhiệt độ da'];
  static const _units = ['%', 'bpm', '°C'];
  static const _samples = [
    [97.0, 98.0, 97.0, 99.0, 98.0, 97.0, 98.0],
    [74.0, 72.0, 76.0, 73.0, 75.0, 74.0, 72.0],
    [33.2, 33.4, 33.3, 33.5, 33.2, 33.3, 33.4],
  ];
  int _metric = 0;
  int _days = 7;
  int? _selected;
  late final DateTime _today = DateTime.now();
  List<double> get _values =>
      List.generate(_days, (i) => _samples[_metric][(i + 7 - _days % 7) % 7]);
  String _number(double value) => value
      .toStringAsFixed(_metric == 2 || value != value.roundToDouble() ? 1 : 0)
      .replaceAll('.', ',');
  String _date(int index) {
    final date = DateTime(
      _today.year,
      _today.month,
      _today.day - _days + 1 + index,
    );
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

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
      side: const WidgetStatePropertyAll(BorderSide(color: Color(0xFFCCDADC))),
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
      border: Border.all(color: const Color(0xFFE0ECE9)),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final values = _values;
    final average = values.reduce((a, b) => a + b) / values.length;
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
                    _selector(
                      ['7 ngày', '30 ngày'],
                      _days == 7 ? 0 : 1,
                      (value) => setState(() {
                        _days = value == 0 ? 7 : 30;
                        _selected = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_labels[_metric]} (${_units[_metric]}) · $_days ngày gần đây',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Dữ liệu mô phỏng',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                          const SizedBox(height: 22),
                          LayoutBuilder(
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
                                label:
                                    'Biểu đồ ${_labels[_metric]}, $_days ngày. Vuốt hoặc chạm để chọn ngày.',
                                value: _selected == null
                                    ? null
                                    : '${_date(_selected!)}: ${_number(values[_selected!])} ${_units[_metric]}',
                                onIncrease: () => setState(
                                  () => _selected = ((_selected ?? 0) + 1)
                                      .clamp(0, values.length - 1),
                                ),
                                onDecrease: () => setState(
                                  () => _selected =
                                      ((_selected ?? values.length - 1) - 1)
                                          .clamp(0, values.length - 1),
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (d) => select(d.localPosition),
                                  onHorizontalDragUpdate: (d) =>
                                      select(d.localPosition),
                                  child: SizedBox(
                                    height: 190,
                                    child: CustomPaint(
                                      painter: _TrendPainter(
                                        values,
                                        _metric,
                                        _selected,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _date(0),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                ),
                              ),
                              Text(
                                _date(_days ~/ 2),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: _muted,
                                ),
                              ),
                              const Text(
                                'Hôm nay',
                                style: TextStyle(fontSize: 11, color: _muted),
                              ),
                            ],
                          ),
                          if (_selected != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${_date(_selected!)} · ${_labels[_metric]}: ${_number(values[_selected!])} ${_units[_metric]}',
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
                            'Mới nhất: ${_number(values.last)} ${_units[_metric]} · Trung bình: ${_number(average)} ${_units[_metric]}',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: _muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Các giá trị mẫu tương tự những lần đo gần đây.',
                            style: TextStyle(
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
                        side: const BorderSide(color: Color(0xFFCCDADC)),
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
    final min = [96.0, 68.0, 33.0][metric];
    final max = [100.0, 80.0, 33.8][metric];
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
          style: const TextStyle(fontSize: 10, color: Color(0xFF657E80)),
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
        ..color = const Color(0xFF008C91)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    for (final p in points) {
      canvas.drawCircle(p, 2.5, Paint()..color = const Color(0xFF008C91));
    }
    if (selected != null) {
      final point = points[selected!];
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, size.height),
        Paint()..color = const Color(0x66008C91),
      );
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
      canvas.drawCircle(point, 5, Paint()..color = const Color(0xFF008C91));
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.metric != metric ||
      oldDelegate.selected != selected ||
      oldDelegate.values != values;
}
