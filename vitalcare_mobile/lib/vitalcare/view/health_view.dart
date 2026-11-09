import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';
import 'measurement_screen.dart';
import 'measurement_history_screen.dart';
import 'health_trends_screen.dart';

/// The patient's latest readings (`/my_vital_signs/latest`), SpO₂ over the
/// last week (`/my_vital_signs/trend`), and whether an open alert
/// (`/my_alerts`) concerns any of them.
class HealthView extends StatefulWidget {
  const HealthView({super.key});

  @override
  State<HealthView> createState() => _HealthViewState();
}

class _HealthViewState extends State<HealthView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _normal = Color(0xFF33846B);
  static const _attention = Color(0xFFB0662A);

  VitalLatest? _latest;
  List<(DateTime, double)> _spo2 = const [];
  List<Alert> _alerts = const [];
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
    });
    final health = Api.instance.health;
    try {
      final now = DateTime.now();
      final from = DateUtils.dateOnly(now).subtract(const Duration(days: 6));
      final results = await Future.wait<Object>([
        health.latest(),
        health.trend(from: from, to: now),
        // Alerts only colour the cards; their failure does not hide the readings.
        health.alerts().catchError((Object _) => const <Alert>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _latest = results[0] as VitalLatest;
        _spo2 = (results[1] as VitalTrend).series(VitalMetric.spo2);
        _alerts = results[2] as List<Alert>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _details(BuildContext context, bool trends) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => trends
            ? const HealthTrendsScreen()
            : const MeasurementHistoryScreen(),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0ECE9)),
    ),
    child: child,
  );

  Widget _metric(
    String label,
    String? value,
    DateTime? at,
    VitalMetric metric,
    IconData icon,
    Color color,
  ) {
    final alerted = _alerts.any((a) => a.isOpen && a.vitalMetric == metric);
    final status = value == null
        ? 'Chưa có dữ liệu'
        : alerted
        ? 'Cần chú ý'
        : 'Bình thường';
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
          const SizedBox(height: 8),
          // The number shrinks to fit its card rather than breaking mid-value on a narrow phone.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value ?? '--',
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              color: value == null
                  ? _muted
                  : alerted
                  ? _attention
                  : _normal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            at == null ? ' ' : relativeTime(at),
            style: const TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  String get _summary {
    final latest = _latest;
    if (latest == null || latest.isEmpty) return 'Chưa có lần đo nào.';
    return [
      'SpO₂ ${latest.spo2 == null ? '--' : decimal(latest.spo2!)}%',
      'Nhịp tim ${latest.heartRate ?? '--'} bpm',
      latest.bodyTemperature != null
          ? 'Cơ thể ${decimal(latest.bodyTemperature!)}°C'
          : 'Da ${latest.skinTemperature == null ? '--' : decimal(latest.skinTemperature!)}°C',
    ].join(' · ');
  }

  /// One of three labels under the chart: each takes a third of the width, so a long date wraps
  /// rather than pushing the row past the screen.
  Widget _chartLabel(String text, TextAlign align) => Expanded(
    child: Text(
      text,
      textAlign: align,
      style: const TextStyle(fontSize: 11, color: _muted),
    ),
  );

  Widget _chart() {
    if (_spo2.length < 2) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Chưa đủ dữ liệu để vẽ biểu đồ.',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ),
      );
    }
    final values = [for (final point in _spo2) point.$2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label:
              'SpO₂ trong 7 ngày, từ cũ đến mới: ${values.map(decimal).join(', ')} phần trăm.',
          child: SizedBox(
            height: 160,
            child: CustomPaint(painter: _Spo2Chart(values)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _chartLabel(relativeDay(_spo2.first.$1), TextAlign.start),
            _chartLabel(
              relativeDay(_spo2[_spo2.length ~/ 2].$1),
              TextAlign.center,
            ),
            _chartLabel(relativeDay(_spo2.last.$1), TextAlign.end),
          ],
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    if (_loading && _latest == null) return const [LoadingBlock()];
    if (_error != null && _latest == null) {
      return [ErrorBlock(error: _error!, onRetry: _load)];
    }
    final latest = _latest;
    return [
      LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            _metric(
              'SpO₂',
              latest?.spo2 == null ? null : '${decimal(latest!.spo2!)}%',
              latest?.spo2At,
              VitalMetric.spo2,
              Icons.water_drop_outlined,
              const Color(0xFF298CAB),
            ),
            _metric(
              'Nhịp tim',
              latest?.heartRate == null ? null : '${latest!.heartRate} bpm',
              latest?.heartRateAt,
              VitalMetric.heartRate,
              Icons.favorite_border_rounded,
              const Color(0xFFD0767F),
            ),
            latest?.bodyTemperature != null
                ? _metric(
                    'Nhiệt độ cơ thể',
                    '${decimal(latest!.bodyTemperature!)}°C',
                    latest.bodyTemperatureAt,
                    VitalMetric.skinTemperature,
                    Icons.thermostat_rounded,
                    const Color(0xFFC28B3A),
                  )
                : _metric(
                    'Nhiệt độ da',
                    latest?.skinTemperature == null
                        ? null
                        : '${decimal(latest!.skinTemperature!)}°C',
                    latest?.skinTemperatureAt,
                    VitalMetric.skinTemperature,
                    Icons.thermostat_rounded,
                    const Color(0xFFC28B3A),
                  ),
          ];
          if (constraints.maxWidth < 320 ||
              MediaQuery.textScalerOf(context).scale(14) > 19) {
            return Column(
              children: [
                for (final card in cards)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(width: double.infinity, child: card),
                  ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: cards[i]),
              ],
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'SpO₂ · 7 ngày gần đây',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đơn vị: % · Trung bình mỗi ngày',
              style: TextStyle(fontSize: 11, color: _muted),
            ),
            const SizedBox(height: 20),
            _chart(),
          ],
        ),
      ),
      const SizedBox(height: 18),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latest?.lastMeasuredAt == null
                        ? 'Lần đo gần nhất'
                        : 'Lần đo gần nhất · ${relativeDay(latest!.lastMeasuredAt!)}, ${clockTime(latest.lastMeasuredAt!)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _summary,
              style: const TextStyle(fontSize: 12, height: 1.5, color: _muted),
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDFF3EF), Color(0xFFF5FAF8)],
        stops: [0, 0.5],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tổng quan sức khỏe',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _latest == null
                        ? ' '
                        : '${_latest!.readings24h} lần đo trong 24 giờ qua',
                    style: const TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 16),
                  ..._content(context),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < 2; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _details(context, i == 1),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _primary,
                              minimumSize: const Size.fromHeight(50),
                              side: const BorderSide(color: Color(0xFFCCDADC)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              i == 0 ? 'Xem lịch sử' : 'Xem xu hướng',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementScreen(),
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.monitor_heart_outlined),
                    label: const Text(
                      'Đo lại',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

class _Spo2Chart extends CustomPainter {
  const _Spo2Chart(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 100.0;
    // 96–100 % as before; widened in steps of 2 when a day was lower.
    final low = math.min(96.0, (values.reduce(math.min) / 2).floor() * 2.0);
    final span = top - low;
    final width = size.width - left - 8;
    final height = size.height - 16;
    final grid = Paint()
      ..color = const Color(0xFFE5EFEB)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = 8 + height * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      final label = TextPainter(
        text: TextSpan(
          text: decimal(top - span * i / 2),
          style: const TextStyle(fontSize: 10, color: Color(0xFF657E80)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final points = List.generate(
      values.length,
      (i) => Offset(
        left + width * i / (values.length - 1),
        8 + (top - values[i].clamp(low, top)) / span * height,
      ),
    );
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(left, size.height)
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
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      canvas.drawCircle(point, 3, Paint()..color = const Color(0xFF008C91));
    }
  }

  @override
  bool shouldRepaint(covariant _Spo2Chart oldDelegate) =>
      oldDelegate.values != values;
}
