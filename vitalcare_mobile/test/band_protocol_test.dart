import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitalcare_mobile/vitalcare/ble/band_protocol.dart';

List<int> hex(String s) => [
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
];

String toHex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('live sample', () {
    final s = LiveSample.fromBytes(hex('78563412440e4e00625f03040201380e'));
    expect(s.epochUtc, 0x12345678);
    expect(s.skinTemperature, 36.52);
    expect(s.heartRate, 78);
    expect(s.spo2, 98);
    expect(s.confidence, 95);
    expect(s.fingerStatus, 3);
    expect(s.flags, 0x04);
    expect(s.seq, 0x0102);
    expect(s.bodyTemperature, 36.40);
    expect(s.heartRateValid, isFalse);
    expect(s.bodyTemperatureValid, isTrue);
  });

  test('live sample with invalid temperatures', () {
    final s = LiveSample.fromBytes([
      0,
      0,
      0,
      0,
      0x00,
      0x80,
      ...List.filled(8, 0),
      0x00,
      0x80,
    ]);
    expect(s.skinTemperature, isNull);
    expect(s.bodyTemperature, isNull);
  });

  test('status', () {
    final s = BandStatus.fromBytes([
      0x02, 0x05, 0x57, 0x00, 0x00, 0x00, 0x65, 0xA4, 0x01, 0x03, //
      0x00, 0x40, 0x9C, 0x00, 0x00, 0x40, 0x42, 0x0F, 0x00,
    ]);
    expect(s.version, 2);
    expect(s.flags, 0x05);
    expect(s.battery, 87);
    expect(s.epochUtc, 0x65000000);
    expect(s.tzMinutes, 420);
    expect(s.pendingSegments, 3);
    expect(s.pendingBytes, 40000);
    expect(s.fsFreeBytes, 1000000);
  });

  test('sync packets', () {
    final data = SyncPacket.fromBytes([0x07, 0x00, 0x02, 0x01, 0x00]);
    expect(data.segmentId, 7);
    expect(data.chunkIndex, 0x0102);
    expect(data.type, SyncPacket.data);

    final end = SyncPacket.fromBytes([
      0x07, 0x00, 0x03, 0x00, 0x01, 0x10, 0x27, 0x00, 0x00, //
      0x26, 0x39, 0xF4, 0xCB,
    ]);
    expect(end.segmentId, 7);
    expect(end.chunkIndex, 3);
    expect(end.type, SyncPacket.segmentEnd);
    expect(end.totalBytes, 10000);
    expect(end.crc, 0xCBF43926);
  });

  test('commands', () {
    final at = DateTime.fromMillisecondsSinceEpoch(
      0x12345678 * 1000,
      isUtc: true,
    );
    expect(toHex(BandCommand.setTime(at, -300)), '0178563412d4fe');
    expect(toHex(BandCommand.syncAck(0x012A)), '032a01');
    expect(toHex(BandCommand.syncStart()), '02');
    expect(toHex(BandCommand.syncAbort()), '04');
  });

  test('crc32', () {
    final bytes = ascii.encode('123456789');
    expect(crc32(bytes), 0xCBF43926);
    expect(crc32(bytes.sublist(4), crc32(bytes.sublist(0, 4))), 0xCBF43926);
  });

  test('csv v3', () {
    final records = parseBandCsv(
      '#v3\nts,t100,tb100,hr,spo2,conf,flags\n'
      '1761550000,3417,3637,62,98,95,128\n'
      '1761550010,3416,3636,64,0,92,160\n'
      '1761550020,3360,0,0,0,0,228\n',
    );
    expect(records, hasLength(3));
    expect(records[0].ts, 1761550000);
    expect(records[0].skin, 34.17);
    expect(records[0].body, 36.37);
    expect(records[0].hr, 62);
    expect(records[0].spo2, 98);
    expect(records[0].confidence, 95);
    expect(records[1].spo2Valid, isFalse);
    expect(records[2].body, isNull);
  });

  test('csv v2', () {
    final records = parseBandCsv(
      '#v2\r\nts,t100,hr,spo2,conf,flags\r\n1761550000,3417,62,98,95,0\r\n',
    );
    expect(records.single.skin, 34.17);
    expect(records.single.body, isNull);
    expect(records.single.hr, 62);
    expect(records.single.spo2, 98);
    expect(records.single.flags, 0);
  });

  test('record to reading', () {
    final ok = const BandRecord(
      ts: 1761550000,
      skin: 34.17,
      body: 36.37,
      hr: 62,
      spo2: 98,
      confidence: 95,
      flags: 0x80,
    ).toReading('VITALCARE-AB12')!;
    expect(ok.clientRecordId, 'VITALCARE-AB12-1761550000');
    expect(ok.measuredAt, DateTime.utc(2025, 10, 27, 7, 26, 40));
    expect(ok.measuredAt.isUtc, isTrue);
    expect(ok.heartRate, 62);
    expect(ok.spo2, 98);
    expect(ok.skinTemperature, 34.17);
    expect(ok.bodyTemperature, 36.37);
    expect(ok.toJson()['bodyTemperature'], 36.37);

    final noBio = parseBandCsv(
      '1761550010,3416,0,64,0,92,${0x04 | 0x20 | 0x40}',
    ).single.toReading('X')!;
    expect(noBio.heartRate, isNull);
    expect(noBio.spo2, isNull);
    expect(noBio.bodyTemperature, isNull);
    expect(noBio.skinTemperature, 34.16);

    expect(
      const BandRecord(ts: 5, skin: 34, hr: 60, flags: 0x01).toReading('X'),
      isNull,
    );
    expect(
      parseBandCsv(
        '1761550020,3360,0,0,0,0,${0x02 | 0x04 | 0x20 | 0x40 | 0x08}',
      ).single.toReading('X'),
      isNull,
    );
  });
}
