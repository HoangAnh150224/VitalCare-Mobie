import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ble/band_link.dart';
import 'common.dart';
import 'measurement_history_screen.dart';

/// One line on what a sync saved, for a notice or the result screen.
String syncSummaryText(BandSyncSummary summary) {
  final parts = [
    summary.accepted == 0 && summary.duplicates == 0
        ? 'Không có lần đo mới để lưu.'
        : 'Đã lưu ${summary.accepted} lần đo lên hệ thống.',
    if (summary.rejected > 0)
      '${summary.rejected} lần đo bị từ chối vì thời gian đo không hợp lệ.',
    if (!summary.finished) 'Chưa đồng bộ hết dữ liệu, hãy thử lại sau.',
  ];
  return parts.join(' ');
}

/// The averages of one measuring session and what was saved.
class MeasurementResultScreen extends StatelessWidget {
  const MeasurementResultScreen({
    super.key,
    required this.measuredAt,
    this.heartRate,
    this.spo2,
    this.bodyTemperature,
    this.skinTemperature,
    this.bodyUncalibrated = false,
    this.sync,
    this.syncError,
  });

  final DateTime measuredAt;
  final double? heartRate;
  final double? spo2;
  final double? bodyTemperature;
  final double? skinTemperature;
  final bool bodyUncalibrated;
  final BandSyncSummary? sync;
  final Object? syncError;
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
    Color color, {
    String note = 'Trung bình lần đo',
  }) {
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
          // The number shrinks to fit its card rather than breaking mid-value on a narrow phone.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
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
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(fontSize: 11, color: Color(0xFF33846B)),
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
                        '$_date · $_time',
                        style: const TextStyle(fontSize: 13, color: _muted),
                      ),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _metric(
                              'SpO₂',
                              spo2 == null ? '--' : '${spo2!.round()}',
                              '%',
                              Icons.water_drop_outlined,
                              const Color(0xFF298CAB),
                            ),
                            _metric(
                              'Nhịp tim',
                              heartRate == null
                                  ? '--'
                                  : '${heartRate!.round()}',
                              ' bpm',
                              Icons.favorite_border_rounded,
                              const Color(0xFFD0767F),
                            ),
                            if (bodyTemperature != null ||
                                skinTemperature == null)
                              _metric(
                                'Nhiệt độ cơ thể (ước tính)',
                                bodyTemperature == null
                                    ? '--'
                                    : decimal(bodyTemperature!),
                                '°C',
                                Icons.thermostat_rounded,
                                const Color(0xFFC28B3A),
                                note: [
                                  'Trung bình lần đo',
                                  if (skinTemperature != null)
                                    'Da ${decimal(skinTemperature!)}°C',
                                  if (bodyUncalibrated) 'chưa hiệu chuẩn',
                                ].join(' · '),
                              )
                            else
                              _metric(
                                'Nhiệt độ da',
                                decimal(skinTemperature!),
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
                                    'Đây là giá trị trung bình trong lần đo này.\nHãy đo đều đặn để theo dõi thay đổi.',
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 21,
                              color: _primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                syncError != null
                                    ? 'Chưa lưu được lên hệ thống: ${errorText(syncError!)} Dữ liệu vẫn còn trên thiết bị, hãy đồng bộ lại sau.'
                                    : sync != null
                                    ? syncSummaryText(sync!)
                                    : 'Kết quả chưa được đồng bộ lên hệ thống.',
                                style: const TextStyle(
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
