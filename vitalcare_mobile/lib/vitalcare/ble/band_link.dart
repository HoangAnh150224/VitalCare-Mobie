import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../api/models.dart';
import 'band_protocol.dart';

/// A failure to show the patient as is (Vietnamese).
class BandException implements Exception {
  const BandException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// What one sync brought up from the band.
class BandSyncSummary {
  int segments = 0;
  int records = 0;
  int accepted = 0;
  int duplicates = 0;
  int invalid = 0;
  int rejected = 0;

  /// False when the band stopped before saying it had sent everything.
  bool finished = false;
}

/// A connection to the patient's VitalCare band over BLE.
class BandLink {
  BandLink._(this.deviceCode, this._device, this._control, this._sync);

  final String deviceCode;
  final BluetoothDevice _device;
  final BluetoothCharacteristic _control;
  final BluetoothCharacteristic _sync;
  final _live = StreamController<LiveSample>.broadcast();
  final status = ValueNotifier<BandStatus?>(null);
  final _subscriptions = <StreamSubscription<Object?>>[];
  bool _syncing = false;

  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Realtime samples, one a second.
  Stream<LiveSample> get live => _live.stream;

  /// Turns false when the band drops the connection.
  final connected = ValueNotifier<bool>(true);

  static const _readings = 500;
  static const _idle = Duration(seconds: 15);

  /// Finds the band advertising as [deviceCode], connects, subscribes and
  /// sets its clock.
  static Future<BandLink> connect(String deviceCode) async {
    if (!supported) {
      throw const BandException(
        'Thiết bị đo chỉ dùng được trên ứng dụng điện thoại.',
      );
    }
    final code = deviceCode.toUpperCase();
    final state = await FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () => BluetoothAdapterState.unknown,
        );
    if (state == BluetoothAdapterState.unauthorized) {
      throw const BandException(
        'Hãy cho phép VitalCare dùng Bluetooth trong phần Cài đặt.',
      );
    }
    if (state != BluetoothAdapterState.on) {
      throw const BandException('Bật Bluetooth để kết nối thiết bị đo.');
    }

    final device =
        FlutterBluePlus.connectedDevices
            .where((d) => d.platformName.toUpperCase() == code)
            .firstOrNull ??
        await _scan(code);
    if (device == null) {
      throw BandException(
        'Không tìm thấy thiết bị $deviceCode. Hãy bật thiết bị và để gần điện thoại.',
      );
    }

    try {
      if (!device.isConnected) {
        await device.connect(
          license: License.nonprofit,
          mtu: null,
          timeout: const Duration(seconds: 15),
        );
      }
      if (Platform.isAndroid) {
        // Larger packets make syncing faster; the band still works at the default MTU, only
        // in smaller chunks, so a refusal is not a reason to fail the connection.
        try {
          await device.requestMtu(185);
        } catch (_) {}
      }
      final service = (await device.discoverServices()).firstWhere(
        (s) => s.uuid == Guid(bandServiceUuid),
      );
      BluetoothCharacteristic char(String uuid) =>
          service.characteristics.firstWhere((c) => c.uuid == Guid(uuid));

      final link = BandLink._(
        code,
        device,
        char(bandControlUuid),
        char(bandSyncUuid),
      );
      final live = char(bandLiveUuid);
      final status = char(bandStatusUuid);
      link._subscriptions
        ..add(
          live.onValueReceived
              .where((v) => v.length >= 16)
              .map(LiveSample.fromBytes)
              .listen(link._live.add),
        )
        ..add(
          status.onValueReceived
              .where((v) => v.length >= 19)
              .listen((v) => link.status.value = BandStatus.fromBytes(v)),
        )
        ..add(
          device.connectionState.listen(
            (s) =>
                link.connected.value = s == BluetoothConnectionState.connected,
          ),
        );
      await live.setNotifyValue(true);
      await status.setNotifyValue(true);
      await link._sync.setNotifyValue(true);
      final current = await status.read();
      if (current.length >= 19) {
        link.status.value = BandStatus.fromBytes(current);
      }
      await link._control.write(BandCommand.setTime(DateTime.now()));
      return link;
    } on BandException {
      rethrow;
    } catch (_) {
      await device.disconnect();
      throw const BandException(
        'Không kết nối được thiết bị đo. Hãy để thiết bị gần điện thoại và thử lại.',
      );
    }
  }

  static Future<BluetoothDevice?> _scan(String code) async {
    BluetoothDevice? found;
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final name = r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName;
        if (found == null && name.toUpperCase() == code) {
          found = r.device;
          FlutterBluePlus.stopScan();
        }
      }
    });
    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.startScan(
      withServices: [Guid(bandServiceUuid)],
      timeout: const Duration(seconds: 12),
    );
    await FlutterBluePlus.isScanning.where((s) => !s).first;
    return found;
  }

  /// Brings up the band's stored segments one by one: each is checked
  /// (size + CRC-32), uploaded with [upload] in batches of 500, and only then
  /// acknowledged so the band may delete it. A bad segment is aborted and
  /// asked for again once; a failed upload aborts and rethrows.
  Future<BandSyncSummary> sync(
    Future<SyncResult> Function(List<DeviceReading>) upload,
  ) async {
    if (_syncing) throw const BandException('Đang đồng bộ dữ liệu.');
    _syncing = true;
    final summary = BandSyncSummary();
    final packets = StreamController<SyncPacket>();
    final source = _sync.onValueReceived
        .where((v) => v.length >= 5)
        .map(SyncPacket.fromBytes)
        .listen(packets.add);
    final queue = StreamIterator(packets.stream);
    final buffer = BytesBuilder(copy: false);
    int? segment;
    var retries = 1;
    try {
      await _control.write(BandCommand.syncStart());
      while (await queue.moveNext().timeout(_idle, onTimeout: () => false)) {
        final packet = queue.current;
        if (packet.type == SyncPacket.done) {
          summary.finished = true;
          break;
        }
        if (packet.type == SyncPacket.data) {
          // Chunk 0 starts the segment again, e.g. after an abort.
          if (packet.segmentId != segment || packet.chunkIndex == 0) {
            buffer.clear();
            segment = packet.segmentId;
          }
          buffer.add(packet.payload);
          continue;
        }
        if (packet.type != SyncPacket.segmentEnd) continue;

        final bytes = packet.segmentId == segment
            ? buffer.takeBytes()
            : Uint8List(0);
        segment = null;
        if (bytes.length != packet.totalBytes || crc32(bytes) != packet.crc) {
          await _control.write(BandCommand.syncAbort());
          if (retries-- <= 0) break;
          await Future<void>.delayed(const Duration(seconds: 1));
          await _control.write(BandCommand.syncStart());
          continue;
        }

        final records = parseBandCsv(utf8.decode(bytes, allowMalformed: true));
        final readings = [for (final r in records) ?r.toReading(deviceCode)];
        try {
          for (var i = 0; i < readings.length; i += _readings) {
            final result = await upload(
              readings.sublist(
                i,
                i + _readings > readings.length
                    ? readings.length
                    : i + _readings,
              ),
            );
            summary
              ..accepted += result.accepted
              ..duplicates += result.duplicates
              ..invalid += result.invalid
              ..rejected += result.rejected;
          }
        } catch (_) {
          await _control.write(BandCommand.syncAbort());
          rethrow;
        }
        await _control.write(BandCommand.syncAck(packet.segmentId));
        summary
          ..segments += 1
          ..records += records.length;
      }
      return summary;
    } finally {
      _syncing = false;
      await source.cancel();
      await queue.cancel();
    }
  }

  Future<void> disconnect() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _live.close();
    connected.value = false;
    try {
      await _device.disconnect();
    } catch (_) {
      // Already gone.
    }
  }
}
