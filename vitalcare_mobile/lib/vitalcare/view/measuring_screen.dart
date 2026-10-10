import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_result_screen.dart';

class MeasuringScreen extends StatefulWidget {
  const MeasuringScreen({super.key});

  @override
  State<MeasuringScreen> createState() => _MeasuringScreenState();
}

class _MeasuringScreenState extends State<MeasuringScreen> {
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);
  late final Timer _timer;
  int _elapsed = 0;
  bool get _complete => _elapsed >= 15;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _elapsed++);
      if (_complete) {
        timer.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MeasurementResultScreen(measuredAt: DateTime.now()),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Widget _metric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(fontSize: 12, color: _ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _complete ? 'Hoàn tất' : 'Đang đo',
            style: const TextStyle(fontSize: 12, color: _primary),
          ),
          const SizedBox(height: 5),
          const Text(
            'Dữ liệu mẫu',
            style: TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_elapsed / 15 * 100).round();
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
          title: Text(
            _complete ? 'Hoàn tất đo' : 'Đang đo',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
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
                      Text(
                        _complete
                            ? 'Đã hoàn tất đo mô phỏng'
                            : 'Đang đo chỉ số sức khỏe',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chế độ mô phỏng · Chưa kết nối thiết bị thực tế',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE0ECE9)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Tiến trình đo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$percent%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                begin: 0,
                                end: _elapsed / 15,
                              ),
                              duration: const Duration(milliseconds: 350),
                              builder: (context, progress, child) =>
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                    color: _primary,
                                    backgroundColor: const Color(0xFFE5EFED),
                                    semanticsLabel: 'Tiến trình đo mô phỏng',
                                    semanticsValue: '$percent%',
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _metric(
                              'SpO₂',
                              '97',
                              '%',
                              Icons.water_drop_outlined,
                              const Color(0xFF298CAB),
                            ),
                            _metric(
                              'Nhịp tim',
                              '74',
                              ' bpm',
                              Icons.favorite_border_rounded,
                              const Color(0xFFD0767F),
                            ),
                            _metric(
                              'Nhiệt độ da',
                              '33,3',
                              '°C',
                              Icons.thermostat_rounded,
                              const Color(0xFFC28B3A),
                            ),
                          ];
                          if (constraints.maxWidth < 300 ||
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
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F2ED),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _complete
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.info_outline_rounded,
                              color: _primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _complete
                                    ? 'Đây là kết quả minh họa, không phải kết quả đo thực tế và không được lưu vào lịch sử.'
                                    : 'Hãy ngồi yên và giữ thiết bị trên người.\nKết quả sẽ hiển thị khi đo xong.',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          side: const BorderSide(color: Color(0xFFCCDADC)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _complete ? 'Quay lại' : 'Hủy',
                          style: const TextStyle(
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
      ),
    );
  }
}
