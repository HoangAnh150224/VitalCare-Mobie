import 'dart:typed_data';

import '../api/models.dart';

/// The VitalCare band's BLE protocol (v2): packet layouts, commands, the
/// segment CSV and CRC-32. Pure Dart so it can be unit tested; the radio side
/// lives in `band_link.dart`.

const bandServiceUuid = '06b40001-765e-4d79-a126-f95ef3affd61';
const bandLiveUuid = '06b40002-765e-4d79-a126-f95ef3affd61';
const bandControlUuid = '06b40003-765e-4d79-a126-f95ef3affd61';
const bandSyncUuid = '06b40004-765e-4d79-a126-f95ef3affd61';
const bandStatusUuid = '06b40005-765e-4d79-a126-f95ef3affd61';

/// Bits of the `flags` byte of a live sample and of a stored record.
abstract final class BandFlag {
  static const timeInvalid = 0x01;
  static const tempInvalid = 0x02;
  static const bioInvalid = 0x04;
  static const loose = 0x08;
  static const spo2Invalid = 0x20;
  static const tempUnstable = 0x40;
  static const tempUncalibrated = 0x80;
}

const _noTemperature = -32768;

double? _temperature(int x100) => x100 == _noTemperature ? null : x100 / 100;

ByteData _bytes(List<int> value) =>
    ByteData.sublistView(Uint8List.fromList(value));

/// One reading the band sends every second (`live`, 16 bytes).
class LiveSample {
  LiveSample.fromBytes(List<int> value) : this._(_bytes(value));

  LiveSample._(ByteData b)
    : epochUtc = b.getUint32(0, Endian.little),
      skinTemperature = _temperature(b.getInt16(4, Endian.little)),
      heartRate = b.getUint16(6, Endian.little),
      spo2 = b.getUint8(8),
      confidence = b.getUint8(9),
      fingerStatus = b.getUint8(10),
      flags = b.getUint8(11),
      seq = b.getUint16(12, Endian.little),
      bodyTemperature = _temperature(b.getInt16(14, Endian.little));

  final int epochUtc;
  final double? skinTemperature;
  final int heartRate;
  final int spo2;
  final int confidence;

  /// 3 = a finger is on the sensor.
  final int fingerStatus;
  final int flags;
  final int seq;
  final double? bodyTemperature;

  bool get hasFinger => fingerStatus == 3;
  bool get heartRateValid => flags & BandFlag.bioInvalid == 0 && heartRate > 0;
  bool get spo2Valid => flags & BandFlag.spo2Invalid == 0 && spo2 > 0;
  bool get skinTemperatureValid =>
      flags & BandFlag.tempInvalid == 0 && skinTemperature != null;

  /// False while the band is still settling to the wrist's temperature.
  bool get bodyTemperatureValid =>
      flags & BandFlag.tempUnstable == 0 && bodyTemperature != null;
  bool get bodyTemperatureUncalibrated =>
      flags & BandFlag.tempUncalibrated != 0;
}

/// The band's state (`status`, 19 bytes).
class BandStatus {
  BandStatus.fromBytes(List<int> value) : this._(_bytes(value));

  BandStatus._(ByteData b)
    : version = b.getUint8(0),
      flags = b.getUint8(1),
      battery = b.getUint8(2) == 0xFF ? null : b.getUint8(2),
      epochUtc = b.getUint32(3, Endian.little),
      tzMinutes = b.getInt16(7, Endian.little),
      pendingSegments = b.getUint16(9, Endian.little),
      pendingBytes = b.getUint32(11, Endian.little),
      fsFreeBytes = b.getUint32(15, Endian.little);

  static const rtcValid = 0x01;
  static const sensorReady = 0x02;
  static const syncing = 0x04;
  static const logOverflow = 0x08;
  static const tempCalibrated = 0x10;

  final int version;
  final int flags;

  /// Percent; null when the band cannot read it.
  final int? battery;
  final int epochUtc;
  final int tzMinutes;
  final int pendingSegments;
  final int pendingBytes;
  final int fsFreeBytes;
}

/// What the phone writes to `control`.
abstract final class BandCommand {
  /// Sets the band's clock; [tzMinutes] defaults to the offset of [now].
  static Uint8List setTime(DateTime now, [int? tzMinutes]) =>
      (ByteData(7)
            ..setUint8(0, 0x01)
            ..setUint32(
              1,
              now.toUtc().millisecondsSinceEpoch ~/ 1000,
              Endian.little,
            )
            ..setInt16(
              5,
              tzMinutes ?? now.timeZoneOffset.inMinutes,
              Endian.little,
            ))
          .buffer
          .asUint8List();

  static Uint8List syncStart() => Uint8List.fromList([0x02]);

  static Uint8List syncAck(int segmentId) =>
      (ByteData(3)
            ..setUint8(0, 0x03)
            ..setUint16(1, segmentId, Endian.little))
          .buffer
          .asUint8List();

  static Uint8List syncAbort() => Uint8List.fromList([0x04]);
}

/// One notification of `sync`: a 5-byte header and its payload.
class SyncPacket {
  SyncPacket.fromBytes(List<int> value)
    : segmentId = _bytes(value).getUint16(0, Endian.little),
      chunkIndex = _bytes(value).getUint16(2, Endian.little),
      type = value[4],
      payload = value.sublist(5);

  static const data = 0;
  static const segmentEnd = 1;
  static const done = 2;

  final int segmentId;
  final int chunkIndex;
  final int type;
  final List<int> payload;

  /// For [segmentEnd]: the segment's size and CRC-32.
  int get totalBytes => _bytes(payload).getUint32(0, Endian.little);
  int get crc => _bytes(payload).getUint32(4, Endian.little);
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

/// CRC-32 as zlib computes it. Pass the previous result as [prev] to continue
/// over more bytes.
int crc32(List<int> data, [int prev = 0]) {
  var c = prev ^ 0xFFFFFFFF;
  for (final byte in data) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

/// One 10-second average the band stored. Values are null when absent (0).
class BandRecord {
  const BandRecord({
    required this.ts,
    this.skin,
    this.body,
    this.hr,
    this.spo2,
    this.confidence = 0,
    this.flags = 0,
  });

  /// UTC epoch seconds at the end of the window.
  final int ts;
  final double? skin;
  final double? body;
  final int? hr;
  final int? spo2;
  final int confidence;
  final int flags;

  bool get timeValid => flags & BandFlag.timeInvalid == 0;
  bool get heartRateValid => flags & BandFlag.bioInvalid == 0 && hr != null;
  bool get spo2Valid => flags & BandFlag.spo2Invalid == 0 && spo2 != null;
  bool get skinTemperatureValid =>
      flags & BandFlag.tempInvalid == 0 && skin != null;
  bool get bodyTemperatureValid =>
      flags & BandFlag.tempUnstable == 0 && body != null;

  /// The reading to upload, or null when the record cannot be placed in time
  /// or holds no valid value.
  DeviceReading? toReading(String deviceCode) {
    if (!timeValid) return null;
    final reading = DeviceReading(
      clientRecordId: '$deviceCode-$ts',
      measuredAt: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
      heartRate: heartRateValid ? hr : null,
      spo2: spo2Valid ? spo2!.toDouble() : null,
      skinTemperature: skinTemperatureValid ? skin : null,
      bodyTemperature: bodyTemperatureValid ? body : null,
    );
    // ponytail: empty records (band off the wrist) are dropped, not sent as INVALID.
    return reading.heartRate == null &&
            reading.spo2 == null &&
            reading.skinTemperature == null &&
            reading.bodyTemperature == null
        ? null
        : reading;
  }
}

int? _present(int value) => value == 0 ? null : value;

/// Parses a segment: `#v3` rows `ts,t100,tb100,hr,spo2,conf,flags`, or `#v2`
/// rows without `tb100`. Header and malformed lines are skipped.
List<BandRecord> parseBandCsv(String csv) {
  final records = <BandRecord>[];
  for (final raw in csv.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty ||
        line.codeUnitAt(0) < 0x30 ||
        line.codeUnitAt(0) > 0x39) {
      continue;
    }
    final cells = line.split(',').map(int.tryParse).toList();
    if ((cells.length != 7 && cells.length != 6) || cells.contains(null)) {
      continue;
    }
    final v = cells.cast<int>();
    final v3 = v.length == 7;
    final t100 = v[1];
    final tb100 = v3 ? v[2] : 0;
    final rest = v3 ? v.sublist(3) : v.sublist(2);
    records.add(
      BandRecord(
        ts: v[0],
        skin: t100 == 0 ? null : t100 / 100,
        body: tb100 == 0 ? null : tb100 / 100,
        hr: _present(rest[0]),
        spo2: _present(rest[1]),
        confidence: rest[2],
        flags: rest[3],
      ),
    );
  }
  return records;
}
