import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_history_screen.dart';

class MeasurementResultScreen extends StatelessWidget {
  const MeasurementResultScreen({super.key, required this.measuredAt});

  final DateTime measuredAt;
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);

  String get _time =>
      '${measuredAt.hour.toString().padLeft(2, '0')}:${measuredAt.minute.toString().padLeft(2, '0')}';
  String get _date =>
      '${measuredAt.day.toString().padLeft(2, '0')}/${measuredAt.month.toString().padLeft(2, '0')}/${measuredAt.year}';

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
            child: Icon(icon, size: 22, color: color),
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
          const Text(
            'Bình thường',
            style: TextStyle(fontSize: 11, color: Color(0xFF33846B)),
          ),
          const SizedBox(height: 5),
          Text(_time, style: const TextStyle(fontSize: 11, color: _muted)),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MeasurementHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            'Kết quả đo',
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
                      const Text(
                        'Kết quả đo mới nhất',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_date · $_time · Dữ liệu mô phỏng',
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _metric(
                              'SpO₂',
                              '98',
                              '%',
                              Icons.water_drop_outlined,
                              const Color(0xFF298CAB),
                            ),
                            _metric(
                              'Nhịp tim',
                              '72',
                              ' bpm',
                              Icons.favorite_border_rounded,
                              const Color(0xFFD0767F),
                            ),
                            _metric(
                              'Nhiệt độ da',
                              '33,4',
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE0ECE9)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: _primary,
                              size: 30,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Đã đo xong',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: _ink,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Các chỉ số mẫu đang ổn định.\nHãy đo đều đặn để theo dõi thay đổi.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F2ED),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 21,
                              color: _primary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Kết quả mô phỏng chưa được lưu hoặc đồng bộ. Kết nối thiết bị để nhận kết quả đo thực tế.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Xong',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _showHistory(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
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
      ),
    );
  }
}
