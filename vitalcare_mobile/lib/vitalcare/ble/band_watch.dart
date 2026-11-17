import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api.dart';
import 'band_link.dart';
import 'band_protocol.dart';

/// Keeps the band connected for as long as the app is open, whatever screen
/// is showing, and sends an abnormal live reading to the server at once
/// instead of waiting for the next sync.
// ponytail: lives only while the app is open; a foreground service (Android) is the upgrade for
// watching with the app closed.
abstract final class BandWatch {
  /// The band in use; null until [connect] succeeds. Replaced on reconnect.
  static final link = ValueNotifier<BandLink?>(null);

  /// What the patient is told while the band reads abnormal; null when fine.
  static final alert = ValueNotifier<String?>(null);

  static const _retryEvery = Duration(seconds: 15);

  static StreamSubscription<LiveSample>? _samples;
  static Timer? _retry;
  static bool _reconnecting = false;

  static Future<BandLink> connect(String deviceCode) async {
    await stop();
    final band = await BandLink.connect(deviceCode);
    _attach(band);
    return band;
  }

  static Future<void> stop() async {
    _retry?.cancel();
    _retry = null;
    await _detach();
    alert.value = null;
  }

  static void _attach(BandLink band) {
    final detector = LiveAlertDetector();
    _samples = band.live.listen((sample) {
      final reading = detector.check(sample, band.deviceCode, DateTime.now());
      if (!detector.abnormal) alert.value = null;
      if (reading != null) _send(band, reading);
    });
    band.connected.addListener(_onConnection);
    link.value = band;
  }

  static Future<void> _detach() async {
    final band = link.value;
    link.value = null;
    band?.connected.removeListener(_onConnection);
    await _samples?.cancel();
    _samples = null;
    await band?.disconnect();
  }

  static Future<void> _send(BandLink band, DeviceReading reading) async {
    alert.value =
        '${reading.alerts.map(alertText).join(', ')}. '
        'Đang báo cho phòng khám và người chăm sóc.';
    try {
      await Api.instance.devices.uploadReadings(band.deviceCode, [
        reading,
      ], battery: band.status.value?.battery);
    } catch (_) {
      // Sent again at the detector's next repeat while the reading stays abnormal.
    }
  }

  static void _onConnection() {
    if (link.value?.connected.value == false) {
      _retry ??= Timer.periodic(_retryEvery, (_) => _reconnect());
    }
  }

  // ponytail: a browser only lets a page pick a Bluetooth device on a click, so on the web this
  // keeps failing quietly until the user presses Connect again; phones reconnect by themselves.
  static Future<void> _reconnect() async {
    final code = link.value?.deviceCode;
    if (_reconnecting || code == null) return;
    _reconnecting = true;
    try {
      final band = await BandLink.connect(code);
      _retry?.cancel();
      _retry = null;
      await _detach();
      _attach(band);
    } catch (_) {
      // Still out of reach: the timer tries again.
    } finally {
      _reconnecting = false;
    }
  }
}
