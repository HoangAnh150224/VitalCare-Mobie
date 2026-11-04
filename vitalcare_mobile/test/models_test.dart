import 'package:flutter_test/flutter_test.dart';
import 'package:vitalcare_mobile/vitalcare/api/models.dart';

void main() {
  test('Appointment reads AppointmentResponse.forCustomer', () {
    final appointment = Appointment.fromJson({
      'id': 12,
      'bookingCode': 'K7M29QXA',
      'customer': {
        'id': 37,
        'customerCode': 'KH0037',
        'fullName': 'Trần Thu Trang',
        'phone': '0901234567',
        'status': 'patient',
      },
      'clinic': {'id': '3f1c', 'name': 'Phòng khám Hòa Bình'},
      'doctor': {'id': 5, 'fullName': 'Nguyễn Văn An', 'specialty': 'Nội khoa'},
      'queueNumber': 7,
      'appointmentDate': '2026-11-05',
      'startTime': '08:30:00',
      'endTime': '08:45:00',
      'reason': 'Khám định kỳ',
      'status': 'checked_in',
      'note': null,
      'examRoom': {'id': 2, 'code': 'P02', 'name': null},
      'paidAt': '2026-11-05T01:10:00Z',
      '_can': {},
    });

    expect(appointment.id, 12);
    expect(appointment.status, AppointmentStatus.checkedIn);
    expect(appointment.status.label, 'Đã tiếp nhận');
    expect(appointment.patientName, 'Trần Thu Trang');
    expect(appointment.clinicName, 'Phòng khám Hòa Bình');
    expect(appointment.doctorName, 'Nguyễn Văn An');
    expect(appointment.queueLabel, '07');
    expect(appointment.date, DateTime(2026, 11, 5));
    expect(appointment.startTime, '08:30');
    expect(appointment.examRoom, 'P02');
    expect(appointment.paidAt!.isUtc, isFalse);
    expect(appointment.isUpcoming(DateTime(2026, 11, 5, 23)), isTrue);
    expect(appointment.isUpcoming(DateTime(2026, 11, 6)), isFalse);
  });

  test('an unknown status or a missing doctor does not break parsing', () {
    final appointment = Appointment.fromJson({
      'id': 1,
      'status': 'something_new',
      'doctor': null,
      'clinic': {'id': 'c', 'name': 'PK'},
    });
    expect(appointment.status, AppointmentStatus.unknown);
    expect(appointment.doctorName, isNull);
    expect(appointment.isUpcoming(DateTime.now()), isFalse);
  });

  test('VitalLatest reads BigDecimal numbers and empty answers', () {
    final latest = VitalLatest.fromJson({
      'heartRate': 76,
      'heartRateAt': '2026-11-02T01:15:00Z',
      'spo2': 97.5,
      'spo2At': '2026-11-02T01:15:00Z',
      'skinTemperature': 33.4,
      'skinTemperatureAt': null,
      'lastMeasuredAt': '2026-11-02T01:15:00Z',
      'readings24h': 12,
    });
    expect(latest.heartRate, 76);
    expect(latest.spo2, 97.5);
    expect(latest.skinTemperature, 33.4);
    expect(latest.readings24h, 12);
    expect(latest.isEmpty, isFalse);

    final none = VitalLatest.fromJson({'readings24h': 0});
    expect(none.isEmpty, isTrue);
    expect(none.lastMeasuredAt, isNull);
  });

  test('VitalTrend orders points and skips those without the metric', () {
    final trend = VitalTrend.fromJson({
      'unit': 'day',
      'points': [
        {
          'at': '2026-11-02T00:00:00',
          'readings': 3,
          'spo2Avg': 97.0,
          'heartRateAvg': 74,
        },
        {
          'at': '2026-11-01T00:00:00',
          'readings': 2,
          'spo2Avg': 98.5,
          'heartRateAvg': null,
        },
      ],
    });
    expect(trend.unit, 'day');
    expect(trend.series(VitalMetric.spo2).map((p) => p.$2), [98.5, 97.0]);
    expect(trend.series(VitalMetric.heartRate), [
      (DateTime(2026, 11, 2), 74.0),
    ]);
    expect(trend.series(VitalMetric.skinTemperature), isEmpty);
  });

  test('Doctor reads its week and the asked day', () {
    final doctor = Doctor.fromJson({
      'id': 5,
      'fullName': 'Nguyễn Văn An',
      'specialty': null,
      'professionalTitle': 'BS.',
      'workingHours': [
        {'dayOfWeek': 1, 'startTime': '08:00:00', 'endTime': '12:00:00'},
        {'dayOfWeek': 3, 'startTime': '13:00:00', 'endTime': '17:00:00'},
      ],
      'day': {
        'date': '2026-11-04',
        'working': true,
        'capacity': 20,
        'taken': 18,
        'remaining': 2,
        'nextNumber': 19,
        'estimatedStart': '11:30:00',
        'estimatedEnd': '11:45:00',
        'bookable': true,
      },
      'manageable': null,
    });
    expect(doctor.label, 'BS. Nguyễn Văn An');
    expect(doctor.workingDays, {1, 3});
    expect(doctor.day!.remaining, 2);
    expect(doctor.day!.estimatedStart, '11:30');
  });

  test('FirstAidArticle splits its body at ## headings', () {
    final article = FirstAidArticle.fromJson({
      'id': 4,
      'title': 'Ngất xỉu',
      'category': 'fainting',
      'summary': 'Khi một người đột ngột bất tỉnh.',
      'body':
          'Giữ bình tĩnh.\n\n## Việc cần làm ngay\n1. Đặt nằm ngửa\n2. Nâng chân\n## Không nên làm\n- Cho uống nước',
      'emergencyWarning': 'Gọi 115 nếu không tỉnh sau 1 phút.',
      'videoUrl': 'https://www.youtube.com/embed/abc',
      'publishedAt': '2026-10-30T03:00:00Z',
    });
    expect(article.category, FirstAidCategory.fainting);
    expect(article.category!.label, 'Ngất xỉu');
    expect(article.sections, [
      (null, 'Giữ bình tĩnh.'),
      ('Việc cần làm ngay', '1. Đặt nằm ngửa\n2. Nâng chân'),
      ('Không nên làm', '- Cho uống nước'),
    ]);
  });

  test('ChatThread reads the conversation and its lines', () {
    final thread = ChatThread.fromJson({
      'conversation': {
        'id': 9,
        'clinicId': '3f1c',
        'clinicName': 'Phòng khám Hòa Bình',
        'unread': 2,
        'aboutCustomerId': null,
      },
      'messages': [
        {
          'id': 1,
          'senderKind': 'CUSTOMER',
          'senderName': 'Trang',
          'mine': true,
          'text': 'Chào bác sĩ',
          'image': false,
          'sentAt': '2026-11-02T01:15:00Z',
          'read': true,
        },
        {
          'id': 2,
          'senderKind': 'STAFF',
          'mine': false,
          'text': null,
          'image': true,
        },
      ],
    });
    expect(thread.conversation.id, 9);
    expect(thread.conversation.unread, 2);
    expect(thread.messages.first.mine, isTrue);
    expect(thread.messages.first.read, isTrue);
    expect(thread.messages.last.image, isTrue);
  });

  test('SharedPatient initials take the given name and the one before', () {
    final patient = SharedPatient.fromJson({
      'permissionId': 1,
      'customerId': 37,
      'fullName': 'Trần Thu Trang',
      'shareVitals': true,
      'shareAlerts': false,
      'shareAppointments': true,
      'expiresAt': null,
    });
    expect(patient.initials, 'TT');
    expect(patient.shareAlerts, isFalse);
  });

  test('DeviceReading leaves out what was not measured', () {
    final reading = DeviceReading(
      clientRecordId: 'r-1',
      measuredAt: DateTime(2026, 11, 2, 8, 15),
      spo2: 97.5,
    ).toJson();
    expect(reading.keys, ['clientRecordId', 'measuredAt', 'spo2']);
    expect(
      reading['measuredAt'],
      matches(RegExp(r'^2026-11-02T08:15:00[+-]\d\d:\d\d$')),
    );
  });

  test('isoDay pads and isoInstant parses back to the same instant', () {
    expect(isoDay(DateTime(2026, 1, 5)), '2026-01-05');
    final time = DateTime(2026, 11, 2, 23, 59, 59);
    expect(DateTime.parse(isoInstant(time)).isAtSameMomentAs(time), isTrue);
  });

  test('jsonList ignores what is not a list of objects', () {
    expect(jsonList(null), isEmpty);
    expect(jsonList({'a': 1}), isEmpty);
    expect(
      jsonList([
        1,
        {'a': 1},
      ]),
      [
        {'a': 1},
      ],
    );
  });
}
