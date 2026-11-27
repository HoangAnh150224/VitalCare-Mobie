import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import '../ble/band_link.dart';
import '../ble/band_protocol.dart';
import 'common.dart';
import 'measurement_result_screen.dart';

/// Uploads what the band stored to the patient's record, then lets the band
/// delete it.
Future<BandSyncSummary> syncBand(BandLink link, String deviceCode) => link.sync(
  (readings, pendingRecords) => Api.instance.devices.uploadReadings(
    deviceCode,
    readings,
    pendingOnDevice: pendingRecords,
    battery: link.status.value?.battery,
  ),
);

/// Shows the band's live readings until [_target] samples have a valid
/// heart rate, then syncs and opens the result.
///
/// Without a [link] (web, desktop, or not connected yet) it only explains
/// that measuring needs the phone app and a connected band.
class MeasuringScreen extends StatefulWidget {
  const MeasuringScreen({super.key, this.link, this.deviceCode});

  final BandLink? link;
  final String? deviceCode;

  @override
  State<MeasuringScreen> createState() => _MeasuringScreenState();
}

class _MeasuringScreenState extends State<MeasuringScreen> {
  static const _primary = Color(0xFF00777C);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF3E5658);
  static const _target = 30;

  StreamSubscription<LiveSample>? _subscription;
  LiveSample? _last;
  final _heartRates = <double>[];
  final _spo2s = <double>[];
  final _bodies = <double>[];
  final _provisionalBodies = <double>[];
  final _skins = <double>[];
  bool _bodyUncalibrated = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.link?.live.listen(_onSample);
    widget.link?.connected.addListener(_onConnection);
  }

  @override
  void dispose() {
    widget.link?.connected.removeListener(_onConnection);
    _subscription?.cancel();
    super.dispose();
  }

  void _onConnection() {
    if (mounted) setState(() {});
  }

  void _onSample(LiveSample sample) {
    if (!mounted || _finishing) return;
    setState(() {
      _last = sample;
      if (sample.heartRateValid) _heartRates.add(sample.heartRate.toDouble());
      if (sample.spo2Valid) _spo2s.add(sample.spo2.toDouble());
      if (sample.bodyTemperatureValid) {
        _bodies.add(sample.bodyTemperature!);
        if (sample.bodyTemperatureUncalibrated) _bodyUncalibrated = true;
      }
      if (sample.bodyTemperatureProvisional) {
        _provisionalBodies.add(sample.bodyTemperature!);
      }
      if (sample.skinTemperatureValid) _skins.add(sample.skinTemperature!);
    });
    if (_heartRates.length >= _target) _finish();
  }

  static double? _average(List<double> values) =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;

  Future<void> _finish() async {
    setState(() => _finishing = true);
    await _subscription?.cancel();
    BandSyncSummary? summary;
    Object? syncError;
    try {
      summary = await syncBand(widget.link!, widget.deviceCode!);
    } catch (e) {
      syncError = e;
    }
    if (!mounted) return;
    // A settled temperature wins; otherwise the band's latest prediction,
    // shown as provisional.
    final settled = _average(_bodies);
    final provisional = settled == null && _provisionalBodies.isNotEmpty
        ? _provisionalBodies.last
        : null;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => MeasurementResultScreen(
          measuredAt: DateTime.now(),
          heartRate: _average(_heartRates),
          spo2: _average(_spo2s),
          bodyTemperature: settled ?? provisional,
          skinTemperature: _average(_skins),
          bodyProvisional: provisional != null,
          bodyUncalibrated: settled != null && _bodyUncalibrated,
          sync: summary,
          syncError: syncError,
        ),
      ),
    );
  }

  String get _bodyNote {
    final last = _last;
    final notes = [
      if (last != null && last.bodyTemperatureProvisional) 'Số tạm thời',
      if (last != null &&
          last.bodyTemperatureValid &&
          last.bodyTemperatureUncalibrated)
        'Chưa hiệu chuẩn',
      if (last != null && last.skinTemperatureValid)
        'Da ${decimal(last.skinTemperature!)}°C',
    ];
    return notes.isEmpty ? 'Ước tính' : notes.join(' · ');
  }

  String get _bodyStatus {
    final last = _last;
    if (last == null || last.bodyTemperatureValid) return 'Đang đo';
    if (last.bodyTemperatureProvisional) return 'Đang ổn định nhiệt…';
    return 'Cần đeo ít nhất 1 phút';
  }

  String get _hint {
    if (widget.link == null) {
      return 'Chưa kết nối thiết bị đo. Thiết bị đo chỉ dùng được trên ứng dụng điện thoại.';
    }
    if (_finishing) return 'Đang lưu kết quả lên hệ thống...';
    if (!widget.link!.connected.value) {
      return 'Mất kết nối với thiết bị đo. Hãy quay lại và kết nối lại.';
    }
    final last = _last;
    if (last == null) return 'Đang chờ số liệu từ thiết bị...';
    if (!last.hasFinger) return 'Đặt ngón tay lên cảm biến';
    return 'Hãy ngồi yên và giữ ngón tay trên cảm biến.\nKết quả sẽ hiển thị khi đo xong.';
  }

  Widget _metric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color, {
    List<double> series = const [],
    String status = 'Đang đo',
    String note = 'Trực tiếp',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBDD3CE)),
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
          // The last minute of readings: level while the value holds, up or down as it moves.
          SizedBox(
            height: 44,
            width: double.infinity,
            child: CustomPaint(
              painter: _TracePainter(
                series.length > _TracePainter.points
                    ? series.sublist(series.length - _TracePainter.points)
                    : series,
                color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(status, style: const TextStyle(fontSize: 12, color: _primary)),
          const SizedBox(height: 5),
          Text(note, style: const TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_heartRates.length / _target).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final last = _last;
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
            'Đang đo',
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
                        'Đang đo chỉ số sức khỏe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.link == null
                            ? 'Chưa kết nối thiết bị đo'
                            : 'Thiết bị ${widget.deviceCode ?? widget.link!.deviceCode}',
                        style: const TextStyle(
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
                          border: Border.all(color: const Color(0xFFBDD3CE)),
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
                              tween: Tween<double>(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 350),
                              builder: (context, progress, child) =>
                                  LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                    color: _primary,
                                    backgroundColor: const Color(0xFFE5EFED),
                                    semanticsLabel: 'Tiến trình đo',
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
                              last != null && last.spo2Valid
                                  ? '${last.spo2}'
                                  : '--',
                              '%',
                              Icons.water_drop_outlined,
                              const Color(0xFF1F6F8A),
                              series: _spo2s,
                            ),
                            _metric(
                              'Nhịp tim',
                              last != null && last.heartRateValid
                                  ? '${last.heartRate}'
                                  : '--',
                              ' bpm',
                              Icons.favorite_border_rounded,
                              const Color(0xFFB23A48),
                              series: _heartRates,
                            ),
                            _metric(
                              'Nhiệt độ cơ thể (ước tính)',
                              last?.bodyTemperature != null
                                  ? decimal(last!.bodyTemperature!)
                                  : '--',
                              '°C',
                              Icons.thermostat_rounded,
                              const Color(0xFF8A5A12),
                              series: _bodies.isNotEmpty
                                  ? _bodies
                                  : _provisionalBodies.isNotEmpty
                                  ? _provisionalBodies
                                  : _skins,
                              status: _bodyStatus,
                              note: _bodyNote,
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
                              last != null && !last.hasFinger
                                  ? Icons.touch_app_outlined
                                  : Icons.info_outline_rounded,
                              color: _primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _hint,
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
                        onPressed: _finishing
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          backgroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54),
                          side: const BorderSide(color: Color(0xFFA9C1BE)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Hủy',
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

/// A measure's last readings, one a second, newest at the right edge: the line
/// runs level while the value holds and steps up or down as it changes. With
/// no reading yet it lies flat and faint along the bottom.
class _TracePainter extends CustomPainter {
  _TracePainter(this.values, this.color);

  static const points = 60;

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height - 5;
    const top = 6.0;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    if (values.isEmpty) {
      canvas.drawLine(
        Offset(0, base),
        Offset(size.width, base),
        line..color = color.withValues(alpha: 0.3),
      );
      return;
    }
    // A few units of room either way, so one step up or down shows without filling the card.
    final low = values.reduce((a, b) => a < b ? a : b) - 3;
    final high = values.reduce((a, b) => a > b ? a : b) + 3;
    final step = size.width / (points - 1);
    Offset at(int i) => Offset(
      size.width - (values.length - 1 - i) * step,
      base - (values[i] - low) / (high - low) * (base - top),
    );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(path, line);
    canvas.drawCircle(at(values.length - 1), 3, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
