/// Typed views of the API's JSON, read leniently: a missing or mistyped field
/// becomes null rather than an exception, because a screen showing "—" is
/// better than a screen that cannot open.
library;

typedef Json = Map<String, dynamic>;

Json _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

List<Json> jsonList(Object? value) => value is List
    ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
    : const [];

int? _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('${value ?? ''}');

double? _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}');

String? _str(Object? value) => value is String ? value : value?.toString();

bool _bool(Object? value) => value == true;

/// An ISO-8601 instant, shown in the phone's time zone.
DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// `YYYY-MM-DD` as a local calendar day.
DateTime? _day(Object? value) {
  if (value is! String || value.length < 10) return null;
  final parsed = DateTime.tryParse(value.substring(0, 10));
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

/// `HH:mm:ss` → `HH:mm`.
String? _clock(Object? value) =>
    value is String && value.length >= 5 ? value.substring(0, 5) : null;

/// `YYYY-MM-DD`, as the API takes a day.
String isoDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// An instant with its offset, as the API takes `from`/`to`.
String isoInstant(DateTime time) {
  final local = time.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  String two(int v) => v.toString().padLeft(2, '0');
  return '${isoDay(local)}T${two(local.hour)}:${two(local.minute)}:${two(local.second)}'
      '$sign$hours:$minutes';
}

// ---- identity -------------------------------------------------------------

class CurrentUser {
  const CurrentUser({required this.id, this.phone, this.email, this.fullName});

  factory CurrentUser.fromJson(Json json) => CurrentUser(
    id: _int(json['id']) ?? 0,
    phone: _str(json['phone']),
    email: _str(json['email']),
    fullName: _str(json['fullName']),
  );

  final int id;
  final String? phone;
  final String? email;
  final String? fullName;
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  factory TokenPair.fromJson(Json json) => TokenPair(
    accessToken: _str(json['accessToken']) ?? '',
    refreshToken: _str(json['refreshToken']) ?? '',
    user: json['user'] is Map ? CurrentUser.fromJson(_map(json['user'])) : null,
  );

  final String accessToken;
  final String refreshToken;
  final CurrentUser? user;
}

class Authorities {
  const Authorities({this.roles = const [], this.permissions = const []});

  factory Authorities.fromJson(Json json) => Authorities(
    roles: (json['roles'] as List? ?? const []).map((e) => '$e').toList(),
    permissions: (json['permissions'] as List? ?? const [])
        .map((e) => '$e')
        .toList(),
  );

  final List<String> roles;
  final List<String> permissions;

  bool can(String permission) => permissions.contains(permission);
}

// ---- profiles -------------------------------------------------------------

/// One of the account's own profiles: itself (`self`) or a dependant.
class Profile {
  const Profile({
    required this.id,
    required this.self,
    required this.fullName,
    this.customerCode,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.relationship,
    this.complete = false,
  });

  factory Profile.fromJson(Json json) => Profile(
    id: _int(json['id']) ?? 0,
    self: _bool(json['self']),
    fullName: _str(json['fullName']) ?? '',
    customerCode: _str(json['customerCode']),
    phone: _str(json['phone']),
    dateOfBirth: _day(json['dateOfBirth']),
    gender: _str(json['gender']),
    relationship: _str(json['relationship']),
    complete: _bool(json['complete']),
  );

  final int id;
  final bool self;
  final String fullName;
  final String? customerCode;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? relationship;

  /// Has what registering a visit needs (date of birth and gender).
  final bool complete;

  String get relationshipLabel => switch (relationship) {
    'child' => 'Con',
    'parent' => 'Cha/mẹ',
    'spouse' => 'Vợ/chồng',
    'sibling' => 'Anh/chị/em',
    _ => self ? 'Bản thân' : 'Người thân',
  };
}

// ---- clinics and doctors --------------------------------------------------

class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    this.address,
    this.phone,
  });

  factory Clinic.fromJson(Json json) => Clinic(
    id: _str(json['id']) ?? '',
    name: _str(json['name']) ?? '',
    address: _str(json['address']),
    phone: _str(json['phone']) ?? _str(json['contactPhone']),
  );

  final String id;
  final String name;
  final String? address;
  final String? phone;
}

/// A doctor's day as `GET /clinics/{id}/doctors?date=` reports it.
class DoctorDay {
  const DoctorDay({
    required this.working,
    required this.remaining,
    required this.bookable,
    this.nextNumber,
    this.estimatedStart,
  });

  factory DoctorDay.fromJson(Json json) => DoctorDay(
    working: _bool(json['working']),
    remaining: _int(json['remaining']) ?? 0,
    bookable: _bool(json['bookable']),
    nextNumber: _int(json['nextNumber']),
    estimatedStart: _clock(json['estimatedStart']),
  );

  final bool working;
  final int remaining;
  final bool bookable;
  final int? nextNumber;
  final String? estimatedStart;
}

class Doctor {
  const Doctor({
    required this.id,
    required this.fullName,
    this.specialty,
    this.professionalTitle,
    this.workingDays = const {},
    this.day,
  });

  factory Doctor.fromJson(Json json) => Doctor(
    id: _int(json['id']) ?? 0,
    fullName: _str(json['fullName']) ?? '',
    specialty: _str(json['specialty']),
    professionalTitle: _str(json['professionalTitle']),
    workingDays: {
      for (final entry in jsonList(json['workingHours']))
        if (_int(entry['dayOfWeek']) != null) _int(entry['dayOfWeek'])!,
    },
    day: json['day'] is Map ? DoctorDay.fromJson(_map(json['day'])) : null,
  );

  final int id;
  final String fullName;
  final String? specialty;
  final String? professionalTitle;

  /// ISO weekdays, 1 = Monday.
  final Set<int> workingDays;
  final DoctorDay? day;

  String get label => professionalTitle == null || professionalTitle!.isEmpty
      ? fullName
      : '$professionalTitle $fullName';
}

/// A profile the clinic already has with the number being registered, as the
/// person registering may see it (BR-14): masked name, birth year only.
class ProfileMatch {
  const ProfileMatch({
    required this.id,
    required this.maskedName,
    this.birthYear,
  });

  final int id;
  final String maskedName;
  final int? birthYear;

  /// "Nguyễn V*** A – 1985".
  String get label =>
      birthYear == null ? maskedName : '$maskedName – $birthYear';

  factory ProfileMatch.fromJson(Json json) => ProfileMatch(
    id: _int(json['id']) ?? 0,
    maskedName: _str(json['maskedName']) ?? '***',
    birthYear: _int(json['birthYear']),
  );
}

// ---- appointments ---------------------------------------------------------

enum AppointmentStatus {
  booked('Đã đặt lịch'),
  checkedIn('Đã check-in, chờ thanh toán'),
  readyForExamination('Đang chờ khám'),
  inExam('Đang khám'),
  awaitingResults('Đang làm chỉ định'),
  completed('Hoàn tất'),
  cancelled('Đã hủy'),
  noShow('Không đến'),
  unknown('Không rõ');

  const AppointmentStatus(this.label);
  final String label;

  static AppointmentStatus parse(Object? value) => switch (value) {
    // 'scheduled' is the name before the booking spec, from an older server.
    'booked' || 'scheduled' => booked,
    'checked_in' => checkedIn,
    'ready_for_examination' => readyForExamination,
    'in_exam' => inExam,
    'awaiting_results' => awaitingResults,
    'completed' => completed,
    'cancelled' => cancelled,
    'no_show' => noShow,
    _ => unknown,
  };

  /// Registered or under way: the visit has not ended.
  bool get isActive =>
      this == booked ||
      this == checkedIn ||
      this == readyForExamination ||
      this == inExam ||
      this == awaitingResults;
}

/// A queue registration: a doctor and a day, with a number in that day.
class Appointment {
  const Appointment({
    required this.id,
    required this.status,
    this.bookingCode,
    this.patientId,
    this.patientName,
    this.clinicId,
    this.clinicName,
    this.doctorId,
    this.doctorName,
    this.specialty,
    this.queueNumber,
    this.date,
    this.startTime,
    this.endTime,
    this.reason,
    this.examRoom,
    this.cancelReason,
    this.paidAt,
    this.deskPaymentChosenAt,
  });

  factory Appointment.fromJson(Json json) {
    final customer = _map(json['customer']);
    final clinic = _map(json['clinic']);
    final doctor = _map(json['doctor']);
    final room = _map(json['examRoom']);
    return Appointment(
      id: _int(json['id']) ?? 0,
      status: AppointmentStatus.parse(json['status']),
      bookingCode: _str(json['bookingCode']),
      patientId: _int(customer['id']),
      patientName: _str(customer['fullName']),
      clinicId: _str(clinic['id']),
      clinicName: _str(clinic['name']),
      doctorId: _int(doctor['id']),
      doctorName: _str(doctor['fullName']),
      specialty: _str(doctor['specialty']),
      queueNumber: _int(json['queueNumber']),
      date: _day(json['appointmentDate']),
      startTime: _clock(json['startTime']),
      endTime: _clock(json['endTime']),
      reason: _str(json['reason']),
      examRoom: _str(room['name']) ?? _str(room['code']),
      cancelReason: _str(json['cancelReason']),
      paidAt: _instant(json['paidAt']),
      deskPaymentChosenAt: _instant(json['deskPaymentChosenAt']),
    );
  }

  final int id;
  final AppointmentStatus status;
  final String? bookingCode;
  final int? patientId;
  final String? patientName;
  final String? clinicId;
  final String? clinicName;
  final int? doctorId;
  final String? doctorName;
  final String? specialty;
  final int? queueNumber;
  final DateTime? date;

  /// About when the number is expected to be called (`HH:mm`); nobody chose it.
  final String? startTime;
  final String? endTime;
  final String? reason;
  final String? examRoom;
  final String? cancelReason;
  final DateTime? paidAt;

  /// UC-01 step 4: when the patient chose to pay the fee at the desk on the day; null: online.
  final DateTime? deskPaymentChosenAt;

  /// The queue number as it is printed and called: `7` → `07`.
  String get queueLabel =>
      queueNumber == null ? '—' : queueNumber.toString().padLeft(2, '0');

  /// Upcoming while it is not over and its day has not passed.
  bool isUpcoming(DateTime today) {
    final day = date;
    if (!status.isActive) return false;
    return day == null ||
        !day.isBefore(DateTime(today.year, today.month, today.day));
  }
}

/// `GET /my_appointments/{id}/queue`.
class AppointmentQueue {
  const AppointmentQueue({
    this.ahead,
    this.awaitingPayment = false,
    this.skipped = false,
    this.returned = false,
  });

  factory AppointmentQueue.fromJson(Json json) => AppointmentQueue(
    ahead: _int(json['ahead']),
    awaitingPayment: _bool(json['awaitingPayment']),
    skipped: _bool(json['skipped']),
    returned: _bool(json['returned']),
  );

  /// How many are before this one in the doctor's line today; null when not waiting.
  final int? ahead;
  final bool awaitingPayment;
  final bool skipped;
  final bool returned;
}

/// `GET /my_appointments/{id}/result`: what the doctor wrote.
class VisitResult {
  const VisitResult({
    this.chiefComplaint,
    this.diagnosis,
    this.conclusion,
    this.followUp,
    this.note,
  });

  factory VisitResult.fromJson(Json json) {
    final encounter = _map(json['encounter']);
    return VisitResult(
      chiefComplaint: _str(encounter['chiefComplaint']),
      diagnosis: _str(encounter['diagnosis']),
      conclusion: _str(encounter['finalConclusion']),
      followUp: _str(encounter['followUp']),
      note: _str(encounter['clinicalNote']),
    );
  }

  final String? chiefComplaint;
  final String? diagnosis;
  final String? conclusion;
  final String? followUp;
  final String? note;
}

// ---- vital signs ----------------------------------------------------------

class VitalLatest {
  const VitalLatest({
    this.heartRate,
    this.heartRateAt,
    this.spo2,
    this.spo2At,
    this.skinTemperature,
    this.skinTemperatureAt,
    this.bodyTemperature,
    this.bodyTemperatureAt,
    this.lastMeasuredAt,
    this.readings24h = 0,
  });

  factory VitalLatest.fromJson(Json json) => VitalLatest(
    heartRate: _int(json['heartRate']),
    heartRateAt: _instant(json['heartRateAt']),
    spo2: _double(json['spo2']),
    spo2At: _instant(json['spo2At']),
    skinTemperature: _double(json['skinTemperature']),
    skinTemperatureAt: _instant(json['skinTemperatureAt']),
    bodyTemperature: _double(json['bodyTemperature']),
    bodyTemperatureAt: _instant(json['bodyTemperatureAt']),
    lastMeasuredAt: _instant(json['lastMeasuredAt']),
    readings24h: _int(json['readings24h']) ?? 0,
  );

  final int? heartRate;
  final DateTime? heartRateAt;
  final double? spo2;
  final DateTime? spo2At;
  final double? skinTemperature;
  final DateTime? skinTemperatureAt;

  /// Estimated from skin temperature by the band (°C).
  final double? bodyTemperature;
  final DateTime? bodyTemperatureAt;
  final DateTime? lastMeasuredAt;
  final int readings24h;

  bool get isEmpty =>
      heartRate == null &&
      spo2 == null &&
      skinTemperature == null &&
      bodyTemperature == null;
}

class VitalReading {
  const VitalReading({
    required this.id,
    required this.measuredAt,
    this.heartRate,
    this.spo2,
    this.skinTemperature,
    this.bodyTemperature,
    this.deviceCode,
  });

  factory VitalReading.fromJson(Json json) => VitalReading(
    id: _int(json['id']) ?? 0,
    measuredAt:
        _instant(json['measuredAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    heartRate: _int(json['heartRate']),
    spo2: _double(json['spo2']),
    skinTemperature: _double(json['skinTemperature']),
    bodyTemperature: _double(json['bodyTemperature']),
    deviceCode: _str(json['deviceCode']),
  );

  final int id;
  final DateTime measuredAt;
  final int? heartRate;
  final double? spo2;
  final double? skinTemperature;
  final double? bodyTemperature;
  final String? deviceCode;
}

/// Which of the three readings a chart or an alert is about.
enum VitalMetric { spo2, heartRate, skinTemperature }

class TrendPoint {
  const TrendPoint({
    required this.at,
    required this.readings,
    this.heartRateAvg,
    this.spo2Avg,
    this.skinTemperatureAvg,
    this.bodyTemperatureAvg,
  });

  factory TrendPoint.fromJson(Json json) => TrendPoint(
    // A clinic-local time without an offset; read as the phone's local time.
    at:
        DateTime.tryParse(_str(json['at']) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    readings: _int(json['readings']) ?? 0,
    heartRateAvg: _double(json['heartRateAvg']),
    spo2Avg: _double(json['spo2Avg']),
    skinTemperatureAvg: _double(json['skinTemperatureAvg']),
    bodyTemperatureAvg: _double(json['bodyTemperatureAvg']),
  );

  final DateTime at;
  final int readings;
  final double? heartRateAvg;
  final double? spo2Avg;
  final double? skinTemperatureAvg;
  final double? bodyTemperatureAvg;

  double? value(VitalMetric metric) => switch (metric) {
    VitalMetric.spo2 => spo2Avg,
    VitalMetric.heartRate => heartRateAvg,
    VitalMetric.skinTemperature => skinTemperatureAvg,
  };
}

class VitalTrend {
  const VitalTrend({required this.unit, required this.points});

  factory VitalTrend.fromJson(Json json) => VitalTrend(
    unit: _str(json['unit']) ?? 'day',
    points: jsonList(json['points']).map(TrendPoint.fromJson).toList()
      ..sort((a, b) => a.at.compareTo(b.at)),
  );

  /// `hour` for windows up to two days, `day` beyond.
  final String unit;
  final List<TrendPoint> points;

  /// The points that have a value for [metric], oldest first.
  List<(DateTime, double)> series(VitalMetric metric) => [
    for (final point in points)
      if (point.value(metric) != null) (point.at, point.value(metric)!),
  ];
}

// ---- devices --------------------------------------------------------------

class MyDevice {
  const MyDevice({
    required this.deviceId,
    required this.deviceCode,
    this.deviceType,
    this.model,
    this.customerId,
    this.customerName,
    this.connectivity,
    this.batteryLevel,
    this.firmwareVersion,
    this.lastSeenAt,
    this.lastSyncAt,
    this.pairedAt,
    this.pairedWithMe = false,
  });

  factory MyDevice.fromJson(Json json) => MyDevice(
    deviceId: _int(json['deviceId']) ?? 0,
    deviceCode: _str(json['deviceCode']) ?? '',
    deviceType: _str(json['deviceType']),
    model: _str(json['model']),
    customerId: _int(json['customerId']),
    customerName: _str(json['customerName']),
    connectivity: _str(json['connectivity']),
    batteryLevel: _int(json['batteryLevel']),
    firmwareVersion: _str(json['firmwareVersion']),
    lastSeenAt: _instant(json['lastSeenAt']),
    lastSyncAt: _instant(json['lastSyncAt']),
    pairedAt: _instant(json['pairedAt']),
    pairedWithMe: _bool(json['pairedWithMe']),
  );

  final int deviceId;
  final String deviceCode;
  final String? deviceType;
  final String? model;
  final int? customerId;
  final String? customerName;

  /// `ONLINE` or `OFFLINE`.
  final String? connectivity;
  final int? batteryLevel;
  final String? firmwareVersion;
  final DateTime? lastSeenAt;
  final DateTime? lastSyncAt;
  final DateTime? pairedAt;
  final bool pairedWithMe;

  bool get online => connectivity == 'ONLINE';
  bool get paired => pairedAt != null;
}

/// One reading the phone forwards from the band (`POST /my_devices/{code}/readings`).
class DeviceReading {
  const DeviceReading({
    required this.clientRecordId,
    required this.measuredAt,
    this.spo2,
    this.heartRate,
    this.skinTemperature,
    this.bodyTemperature,
  });

  final String clientRecordId;
  final DateTime measuredAt;
  final double? spo2;
  final int? heartRate;
  final double? skinTemperature;
  final double? bodyTemperature;

  Json toJson() => {
    'clientRecordId': clientRecordId,
    'measuredAt': isoInstant(measuredAt),
    'spo2': ?spo2,
    'heartRate': ?heartRate,
    'skinTemperature': ?skinTemperature,
    'bodyTemperature': ?bodyTemperature,
  };
}

class SyncRecordResult {
  const SyncRecordResult({
    required this.clientRecordId,
    required this.outcome,
    this.reason,
  });

  factory SyncRecordResult.fromJson(Json json) => SyncRecordResult(
    clientRecordId: _str(json['clientRecordId']) ?? '',
    outcome: _str(json['outcome']) ?? '',
    reason: _str(json['reason']),
  );

  final String clientRecordId;

  /// `ACCEPTED`, `DUPLICATE`, `INVALID` or `REJECTED`.
  final String outcome;
  final String? reason;
}

class SyncResult {
  const SyncResult({
    required this.status,
    this.accepted = 0,
    this.duplicates = 0,
    this.invalid = 0,
    this.rejected = 0,
    this.records = const [],
  });

  factory SyncResult.fromJson(Json json) => SyncResult(
    status: _str(json['status']) ?? '',
    accepted: _int(json['accepted']) ?? 0,
    duplicates: _int(json['duplicates']) ?? 0,
    invalid: _int(json['invalid']) ?? 0,
    rejected: _int(json['rejected']) ?? 0,
    records: jsonList(json['records']).map(SyncRecordResult.fromJson).toList(),
  );

  final String status;
  final int accepted;
  final int duplicates;
  final int invalid;
  final int rejected;
  final List<SyncRecordResult> records;
}

// ---- alerts and notifications ---------------------------------------------

class Alert {
  const Alert({
    required this.id,
    this.patientId,
    this.patientName,
    this.metric,
    this.severity,
    this.status,
    this.message,
    this.measuredValue,
    this.triggeredAt,
    this.lastTriggeredAt,
  });

  factory Alert.fromJson(Json json) {
    final patient = _map(json['patient']);
    return Alert(
      id: _int(json['id']) ?? 0,
      patientId: _int(patient['customerId']),
      patientName: _str(patient['fullName']),
      metric: _str(json['metric']),
      severity: _str(json['severity']),
      status: _str(json['status']),
      message: _str(json['message']),
      measuredValue: _double(json['measuredValue']),
      triggeredAt: _instant(json['triggeredAt']),
      lastTriggeredAt: _instant(json['lastTriggeredAt']),
    );
  }

  final int id;
  final int? patientId;
  final String? patientName;

  /// `HEART_RATE`, `SPO2` or `SKIN_TEMPERATURE`.
  final String? metric;

  /// `WARNING` or `CRITICAL`.
  final String? severity;

  /// `OPEN`, `ACKNOWLEDGED`, `RESOLVED` or `DISMISSED`.
  final String? status;
  final String? message;
  final double? measuredValue;
  final DateTime? triggeredAt;
  final DateTime? lastTriggeredAt;

  bool get isOpen => status == 'OPEN' || status == 'ACKNOWLEDGED';

  VitalMetric? get vitalMetric => switch (metric) {
    'SPO2' => VitalMetric.spo2,
    'HEART_RATE' => VitalMetric.heartRate,
    'SKIN_TEMPERATURE' => VitalMetric.skinTemperature,
    _ => null,
  };
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    this.type,
    this.level,
    this.body,
    this.link,
    this.read = false,
    this.alertId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Json json) => AppNotification(
    id: _int(json['id']) ?? 0,
    title: _str(json['title']) ?? '',
    type: _str(json['type']),
    level: _str(json['level']),
    body: _str(json['body']),
    link: _str(json['link']),
    read: _bool(json['read']),
    alertId: _int(json['alertId']),
    createdAt: _instant(json['createdAt']),
  );

  final int id;
  final String title;
  final String? type;

  /// `INFO`, `SUCCESS`, `WARNING` or `ERROR`.
  final String? level;
  final String? body;

  /// A path on the web app; the phone does not follow it.
  final String? link;
  final bool read;
  final int? alertId;
  final DateTime? createdAt;

  AppNotification markedRead() => AppNotification(
    id: id,
    title: title,
    type: type,
    level: level,
    body: body,
    link: link,
    read: true,
    alertId: alertId,
    createdAt: createdAt,
  );
}

// ---- first aid ------------------------------------------------------------

enum FirstAidCategory {
  respiratory('Hô hấp'),
  fainting('Ngất xỉu'),
  fever('Sốt'),
  wound('Vết thương'),
  injury('Chấn thương'),
  environment('Môi trường'),
  general('Tổng quát');

  const FirstAidCategory(this.label);
  final String label;

  static FirstAidCategory? parse(Object? value) {
    for (final category in values) {
      if (category.name == value) return category;
    }
    return null;
  }
}

class FirstAidArticle {
  const FirstAidArticle({
    required this.id,
    required this.title,
    this.category,
    this.summary,
    this.body,
    this.emergencyWarning,
    this.videoUrl,
    this.publishedAt,
  });

  factory FirstAidArticle.fromJson(Json json) => FirstAidArticle(
    id: _int(json['id']) ?? 0,
    title: _str(json['title']) ?? '',
    category: FirstAidCategory.parse(json['category']),
    summary: _str(json['summary']),
    body: _str(json['body']),
    emergencyWarning: _str(json['emergencyWarning']),
    videoUrl: _str(json['videoUrl']),
    publishedAt: _instant(json['publishedAt']),
  );

  final int id;
  final String title;
  final FirstAidCategory? category;
  final String? summary;

  /// Plain text; a line starting `## ` begins a heading.
  final String? body;
  final String? emergencyWarning;

  /// A Google Drive or YouTube link, opened outside the app.
  final String? videoUrl;
  final DateTime? publishedAt;

  /// [body] split at its `## ` headings; text before the first heading has
  /// a null heading.
  List<(String?, String)> get sections {
    final result = <(String?, String)>[];
    String? heading;
    final buffer = StringBuffer();
    void flush() {
      final text = buffer.toString().trim();
      if (text.isNotEmpty || heading != null) result.add((heading, text));
      buffer.clear();
    }

    for (final line in (body ?? '').split('\n')) {
      if (line.startsWith('## ')) {
        flush();
        heading = line.substring(3).trim();
      } else {
        buffer.writeln(line);
      }
    }
    flush();
    return result;
  }
}

// ---- conversations --------------------------------------------------------

class Conversation {
  const Conversation({
    required this.id,
    this.clinicId,
    this.clinicName,
    this.clinicPhone,
    this.status,
    this.lastMessageAt,
    this.lastMessagePreview,
    this.lastSenderKind,
    this.unread = 0,
    this.aboutCustomerId,
    this.aboutName,
  });

  factory Conversation.fromJson(Json json) => Conversation(
    id: _int(json['id']) ?? 0,
    clinicId: _str(json['clinicId']),
    clinicName: _str(json['clinicName']),
    clinicPhone: _str(json['clinicPhone']),
    status: _str(json['status']),
    lastMessageAt: _instant(json['lastMessageAt']),
    lastMessagePreview: _str(json['lastMessagePreview']),
    lastSenderKind: _str(json['lastSenderKind']),
    unread: _int(json['unread']) ?? 0,
    aboutCustomerId: _int(json['aboutCustomerId']),
    aboutName: _str(json['aboutName']),
  );

  final int id;
  final String? clinicId;
  final String? clinicName;
  final String? clinicPhone;
  final String? status;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final String? lastSenderKind;
  final int unread;

  /// Set when a caregiver writes about the patient who shares with them.
  final int? aboutCustomerId;
  final String? aboutName;
}

class ChatLine {
  const ChatLine({
    required this.id,
    required this.mine,
    this.senderKind,
    this.senderName,
    this.text,
    this.image = false,
    this.sentAt,
    this.read = false,
  });

  factory ChatLine.fromJson(Json json) => ChatLine(
    id: _int(json['id']) ?? 0,
    mine: _bool(json['mine']),
    senderKind: _str(json['senderKind']),
    senderName: _str(json['senderName']),
    text: _str(json['text']),
    image: _bool(json['image']),
    sentAt: _instant(json['sentAt']),
    read: _bool(json['read']),
  );

  final int id;
  final bool mine;
  final String? senderKind;
  final String? senderName;
  final String? text;
  final bool image;
  final DateTime? sentAt;
  final bool read;
}

class ChatThread {
  const ChatThread({required this.conversation, required this.messages});

  factory ChatThread.fromJson(Json json) => ChatThread(
    conversation: Conversation.fromJson(_map(json['conversation'])),
    messages: jsonList(json['messages']).map(ChatLine.fromJson).toList(),
  );

  final Conversation conversation;
  final List<ChatLine> messages;
}

// ---- sharing and caregivers -----------------------------------------------

class SharingPermission {
  const SharingPermission({
    required this.id,
    required this.status,
    this.customerId,
    this.customerName,
    this.caregiverName,
    this.caregiverPhone,
    this.shareVitals = false,
    this.shareAlerts = false,
    this.shareAppointments = false,
    this.emergencyPhone,
    this.expiresAt,
  });

  factory SharingPermission.fromJson(Json json) => SharingPermission(
    id: _int(json['id']) ?? 0,
    status: _str(json['status']) ?? '',
    customerId: _int(json['customerId']),
    customerName: _str(json['customerName']),
    caregiverName: _str(json['caregiverName']),
    caregiverPhone: _str(json['caregiverPhone']),
    shareVitals: _bool(json['shareVitals']),
    shareAlerts: _bool(json['shareAlerts']),
    shareAppointments: _bool(json['shareAppointments']),
    emergencyPhone: _str(json['emergencyPhone']),
    expiresAt: _instant(json['expiresAt']),
  );

  final int id;

  /// `ACTIVE`, `EXPIRED` or `REVOKED`.
  final String status;
  final int? customerId;
  final String? customerName;
  final String? caregiverName;
  final String? caregiverPhone;
  final bool shareVitals;
  final bool shareAlerts;
  final bool shareAppointments;
  final String? emergencyPhone;
  final DateTime? expiresAt;

  bool get active => status == 'ACTIVE';
}

/// A patient who shares with the signed-in caregiver.
class SharedPatient {
  const SharedPatient({
    required this.permissionId,
    required this.customerId,
    required this.fullName,
    this.customerCode,
    this.shareVitals = false,
    this.shareAlerts = false,
    this.shareAppointments = false,
    this.expiresAt,
  });

  factory SharedPatient.fromJson(Json json) => SharedPatient(
    permissionId: _int(json['permissionId']) ?? 0,
    customerId: _int(json['customerId']) ?? 0,
    fullName: _str(json['fullName']) ?? '',
    customerCode: _str(json['customerCode']),
    shareVitals: _bool(json['shareVitals']),
    shareAlerts: _bool(json['shareAlerts']),
    shareAppointments: _bool(json['shareAppointments']),
    expiresAt: _instant(json['expiresAt']),
  );

  final int permissionId;
  final int customerId;
  final String fullName;
  final String? customerCode;
  final bool shareVitals;
  final bool shareAlerts;
  final bool shareAppointments;
  final DateTime? expiresAt;

  String get initials {
    final words = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.length > 1 ? words[words.length - 2][0] : '';
    return (first + words.last[0]).toUpperCase();
  }
}

/// An emergency notice sent to a caregiver about a patient's alert.
class EmergencyNotice {
  const EmergencyNotice({
    required this.id,
    this.alertId,
    this.severity,
    this.message,
    this.customerId,
    this.patientName,
    this.emergencyPhone,
    this.status,
    this.notifiedAt,
    this.acknowledgedAt,
  });

  factory EmergencyNotice.fromJson(Json json) => EmergencyNotice(
    id: _int(json['id']) ?? 0,
    alertId: _int(json['alertId']),
    severity: _str(json['severity']),
    message: _str(json['message']),
    customerId: _int(json['customerId']),
    patientName: _str(json['patientName']),
    emergencyPhone: _str(json['emergencyPhone']),
    status: _str(json['status']),
    notifiedAt: _instant(json['notifiedAt']),
    acknowledgedAt: _instant(json['acknowledgedAt']),
  );

  final int id;
  final int? alertId;
  final String? severity;
  final String? message;
  final int? customerId;
  final String? patientName;
  final String? emergencyPhone;
  final String? status;
  final DateTime? notifiedAt;
  final DateTime? acknowledgedAt;
}
