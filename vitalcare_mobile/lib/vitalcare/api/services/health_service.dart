import '../api_client.dart';
import '../models.dart';

/// A page of readings and how many there are in all (`X-Total-Count`).
class ReadingPage {
  const ReadingPage(this.readings, this.total);
  final List<VitalReading> readings;
  final int total;
}

/// The patient's own vital signs (`/my_vital_signs`) and alerts (`/my_alerts`).
///
/// [profileId] picks one of the account's dependants; null is the account itself.
class HealthService {
  HealthService(this._client);

  final ApiClient _client;

  Future<VitalLatest> latest({int? profileId}) async => VitalLatest.fromJson(
    _json(
      await _client.get(
        '/my_vital_signs/latest',
        query: {'profileId': profileId},
      ),
    ),
  );

  /// Valid readings measured in [from, to), newest first.
  Future<ReadingPage> history({
    required DateTime from,
    DateTime? to,
    int? profileId,
    int limit = 200,
  }) async {
    final response = await _client.send(
      'GET',
      '/my_vital_signs',
      query: {
        'profileId': profileId,
        'from': isoInstant(from),
        'to': to == null ? null : isoInstant(to),
        '_start': 0,
        '_end': limit,
      },
    );
    final readings = jsonList(
      response.body,
    ).map(VitalReading.fromJson).toList();
    return ReadingPage(readings, response.totalCount ?? readings.length);
  }

  /// Hourly buckets for up to two days, daily beyond (at most 92 days).
  Future<VitalTrend> trend({
    required DateTime from,
    DateTime? to,
    int? profileId,
  }) async => VitalTrend.fromJson(
    _json(
      await _client.get(
        '/my_vital_signs/trend',
        query: {
          'profileId': profileId,
          'from': isoInstant(from),
          'to': to == null ? null : isoInstant(to),
        },
      ),
    ),
  );

  Future<List<Alert>> alerts({int? profileId, int limit = 20}) async =>
      jsonList(
        await _client.get(
          '/my_alerts',
          query: {'profileId': profileId, '_start': 0, '_end': limit},
        ),
      ).map(Alert.fromJson).toList();

  static Json _json(Object? body) =>
      body is Map ? body.cast<String, dynamic>() : const {};
}

/// The devices worn by the account's profiles (`/my_devices`), pairing them
/// with this phone, and forwarding their readings when the phone is the
/// band's gateway.
class DeviceService {
  DeviceService(this._client);

  final ApiClient _client;

  Future<List<MyDevice>> list() async => jsonList(
    await _client.get('/my_devices'),
  ).map(MyDevice.fromJson).toList();

  /// 404 when the device is not assigned to this account; 409 when another
  /// phone holds it.
  Future<MyDevice> pair(String deviceCode) async => MyDevice.fromJson(
    _json(
      await _client.post('/my_devices/pair', body: {'deviceCode': deviceCode}),
    ),
  );

  Future<MyDevice> unpair(String deviceCode) async => MyDevice.fromJson(
    _json(
      await _client.delete(
        '/my_devices/${Uri.encodeComponent(deviceCode)}/pair',
      ),
    ),
  );

  /// Sends readings the phone collected from the band, signed in as the
  /// patient. Each [DeviceReading.clientRecordId] makes a resend harmless.
  Future<SyncResult> uploadReadings(
    String deviceCode,
    List<DeviceReading> readings, {
    String? clientBatchId,
    int? pendingOnDevice,
    int? battery,
    String? firmware,
  }) async => SyncResult.fromJson(
    _json(
      await _client.post(
        '/my_devices/${Uri.encodeComponent(deviceCode)}/readings',
        body: _upload(
          readings,
          clientBatchId,
          pendingOnDevice,
          battery,
          firmware,
        ),
      ),
    ),
  );

  static Json _upload(
    List<DeviceReading> readings,
    String? clientBatchId,
    int? pendingOnDevice,
    int? battery,
    String? firmware,
  ) => {
    'clientBatchId': ?clientBatchId,
    'pendingOnDevice': ?pendingOnDevice,
    'battery': ?battery,
    'firmware': ?firmware,
    'readings': [for (final reading in readings) reading.toJson()],
  };

  static Json _json(Object? body) =>
      body is Map ? body.cast<String, dynamic>() : const {};
}
