import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measuring_screen.dart';

class MeasurementScreen extends StatelessWidget {
  const MeasurementScreen({super.key});

  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);

  void _startMeasurement(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MeasuringScreen()));
  }

  Widget _metric(String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0ECE9)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step(int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE4F4EF),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            tooltip: 'Quay lại trang chủ',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text(
            'Đo sức khỏe',
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD9EAE5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F6F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.watch_outlined,
                                    size: 30,
                                    color: _primary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Thiết bị VitalCare',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Đã kết nối · Trạng thái mẫu',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _primary,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.battery_5_bar_rounded,
                                            size: 18,
                                            color: _primary,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Pin 82%',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: _muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                height: 1,
                                color: Color(0xFFE3EEEB),
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: _primary,
                                  size: 19,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bạn đã sẵn sàng đo.',
                                    style: TextStyle(fontSize: 14, color: _ink),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Các chỉ số được đo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _metric(
                            'SpO₂',
                            Icons.water_drop_outlined,
                            const Color(0xFF298CAB),
                          ),
                          const SizedBox(width: 10),
                          _metric(
                            'Nhịp tim',
                            Icons.favorite_border_rounded,
                            const Color(0xFFD0767F),
                          ),
                          const SizedBox(width: 10),
                          _metric(
                            'Nhiệt độ da',
                            Icons.thermostat_rounded,
                            const Color(0xFFC28B3A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Trước khi bắt đầu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _step(
                        1,
                        'Đeo thiết bị đúng cách',
                        'Đảm bảo thiết bị vừa vặn và tiếp xúc với da.',
                      ),
                      _step(
                        2,
                        'Ngồi yên và thư giãn',
                        'Giữ tư thế thoải mái trong suốt quá trình đo.',
                      ),
                      _step(
                        3,
                        'Chờ kết quả đo',
                        'Hạn chế cử động cho đến khi đo hoàn tất.',
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => _startMeasurement(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(
                          Icons.monitor_heart_outlined,
                          size: 22,
                        ),
                        label: const Text(
                          'Bắt đầu đo',
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
      ),
    );
  }
}
