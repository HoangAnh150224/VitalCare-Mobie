import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import '../ble/band_link.dart';
import 'common.dart';
import 'measurement_result_screen.dart';
import 'measuring_screen.dart';

class MeasurementScreen extends StatefulWidget {
  const MeasurementScreen({super.key});

  @override
  State<MeasurementScreen> createState() => _MeasurementScreenState();
}

/// The device card shows the band assigned to the patient (`/my_devices`);
/// the phone connects to it over Bluetooth, pairs with it, and syncs it.
class _MeasurementScreenState extends State<MeasurementScreen> {
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);

  MyDevice? _device;
  bool _loading = true;
  Object? _error;
  BandLink? _link;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _link?.status.removeListener(_onStatus);
    _link?.connected.removeListener(_onStatus);
    _link?.disconnect();
    super.dispose();
  }

  void _onStatus() {
    if (mounted) setState(() {});
  }

  bool get _connected => _link?.connected.value == true;

  /// Finds the band over Bluetooth, then pairs this phone with it.
  Future<void> _connect() async {
    final device = _device;
    if (device == null || _busy) return;
    setState(() => _busy = true);
    BandLink? link;
    try {
      _link?.status.removeListener(_onStatus);
      _link?.connected.removeListener(_onStatus);
      await _link?.disconnect();
      _link = null;
      link = await BandLink.connect(device.deviceCode);
      final paired = device.pairedWithMe
          ? device
          : await Api.instance.devices.pair(device.deviceCode);
      if (!mounted) {
        await link.disconnect();
        return;
      }
      link.status.addListener(_onStatus);
      link.connected.addListener(_onStatus);
      setState(() {
        _device = paired;
        _link = link;
      });
    } catch (e) {
      await link?.disconnect();
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    final link = _link;
    final device = _device;
    if (link == null || device == null || _busy) return;
    setState(() => _busy = true);
    try {
      final summary = await syncBand(link, device.deviceCode);
      if (mounted) showNotice(context, syncSummaryText(summary));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await Api.instance.devices.list();
      if (!mounted) return;
      setState(
        () => _device =
            devices.where((d) => d.pairedWithMe).firstOrNull ??
            devices.firstOrNull,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _deviceName {
    final device = _device;
    if (device == null) return 'Thiết bị VitalCare';
    return device.model == null || device.model!.isEmpty
        ? device.deviceCode
        : '${device.model} · ${device.deviceCode}';
  }

  String get _deviceStatus {
    if (_loading) return 'Đang tải thông tin thiết bị...';
    if (_error != null) return errorText(_error!);
    final device = _device;
    if (device == null) return 'Chưa được giao thiết bị';
    if (_connected) return 'Đã kết nối qua Bluetooth';
    final seen = device.lastSeenAt == null
        ? ''
        : ' · ${ago(device.lastSeenAt!)}';
    return '${device.online ? 'Đang kết nối' : 'Mất kết nối'}$seen';
  }

  String get _readiness {
    final device = _device;
    if (_loading) return 'Đang kiểm tra thiết bị.';
    if (device == null) {
      return 'Bạn chưa được gán thiết bị đo. Liên hệ phòng khám để được cấp thiết bị.';
    }
    if (_busy && !_connected) return 'Đang tìm thiết bị đo...';
    if (!_connected) {
      return 'Bật thiết bị đo, để gần điện thoại rồi bấm Kết nối.';
    }
    final pending = _link!.status.value?.pendingSegments ?? 0;
    return pending > 0
        ? 'Bạn đã sẵn sàng đo. Thiết bị còn $pending phần dữ liệu chưa đồng bộ.'
        : 'Bạn đã sẵn sàng đo.';
  }

  int? get _battery => _connected
      ? _link!.status.value?.battery ?? _device?.batteryLevel
      : _device?.batteryLevel;

  void _startMeasurement() {
    final link = _link;
    final device = _device;
    if (link == null || device == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MeasuringScreen(link: link, deviceCode: device.deviceCode),
      ),
    );
  }

  ButtonStyle get _filled => FilledButton.styleFrom(
    backgroundColor: _primary,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(56),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static const _label = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);

  static const _spinner = SizedBox.square(
    dimension: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );

  List<Widget> get _actions {
    if (_device == null) return const [];
    if (!_connected) {
      return [
        FilledButton.icon(
          onPressed: _busy ? null : _connect,
          style: _filled,
          icon: _busy
              ? _spinner
              : const Icon(Icons.bluetooth_rounded, size: 22),
          label: const Text('Kết nối', style: _label),
        ),
      ];
    }
    return [
      FilledButton.icon(
        onPressed: _busy ? null : _startMeasurement,
        style: _filled,
        icon: const Icon(Icons.monitor_heart_outlined, size: 22),
        label: const Text('Bắt đầu đo', style: _label),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _busy ? null : _sync,
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          backgroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: Color(0xFFCCDADC)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _busy ? _spinner : const Icon(Icons.sync_rounded, size: 22),
        label: const Text(
          'Đồng bộ dữ liệu',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    ];
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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _deviceName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      GestureDetector(
                                        onTap: _error == null ? null : _load,
                                        child: Text(
                                          _deviceStatus,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: _primary,
                                          ),
                                        ),
                                      ),
                                      if (_battery != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.battery_5_bar_rounded,
                                              size: 18,
                                              color: _primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pin $_battery%',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: _muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
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
                            Row(
                              children: [
                                Icon(
                                  _connected
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.info_outline_rounded,
                                  color: _primary,
                                  size: 19,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _readiness,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: _ink,
                                    ),
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
                            'Nhiệt độ cơ thể',
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
                      ..._actions,
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
