import 'package:flutter/material.dart';
import 'measurement_screen.dart';
import 'measurement_history_screen.dart';
import 'health_trends_screen.dart';

class HealthView extends StatelessWidget {
  const HealthView({super.key});
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _values = [97.0, 98.0, 97.0, 99.0, 98.0, 98.0, 98.0];

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

  Widget _metric(String label, String value, IconData icon, Color color) =>
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bình thường',
              style: TextStyle(fontSize: 11, color: Color(0xFF33846B)),
            ),
            const SizedBox(height: 5),
            const Text(
              'Hôm nay 09:41',
              style: TextStyle(fontSize: 10, color: _muted),
            ),
          ],
        ),
      );

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
      child: SingleChildScrollView(
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
                const Text(
                  'Dữ liệu mẫu',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _metric(
                        'SpO₂',
                        '98%',
                        Icons.water_drop_outlined,
                        const Color(0xFF298CAB),
                      ),
                      _metric(
                        'Nhịp tim',
                        '72 bpm',
                        Icons.favorite_border_rounded,
                        const Color(0xFFD0767F),
                      ),
                      _metric(
                        'Nhiệt độ da',
                        '33,4°C',
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
                              child: SizedBox(
                                width: double.infinity,
                                child: card,
                              ),
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
                        'Đơn vị: % · Dữ liệu mẫu',
                        style: TextStyle(fontSize: 11, color: _muted),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        label:
                            'SpO₂ mẫu trong 7 ngày, từ cũ đến mới: 97, 98, 97, 99, 98, 98, 98 phần trăm.',
                        child: const SizedBox(
                          height: 160,
                          child: CustomPaint(painter: _Spo2Chart(_values)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '6 ngày trước',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                          Text(
                            '3 ngày trước',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                          Text(
                            'Hôm nay',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _card(
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 20,
                            color: _primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lần đo gần nhất · Hôm nay, 09:41',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'SpO₂ 98% · Nhịp tim 72 bpm · Da 33,4°C',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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
          text: '${100 - i * 2}',
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
        8 + (100 - values[i]) / 4 * height,
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
