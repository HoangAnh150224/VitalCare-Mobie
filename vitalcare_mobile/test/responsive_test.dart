// Every screen at the phone sizes people use, upright and on its side, at normal and large text:
// none may overflow. A failure lists each screen × size × text scale that did.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalcare_mobile/main.dart';
import 'package:vitalcare_mobile/vitalcare/api/api.dart';
import 'package:vitalcare_mobile/vitalcare/api/api_client.dart';
import 'package:vitalcare_mobile/vitalcare/api/session_store.dart';
import 'package:vitalcare_mobile/vitalcare/ble/band_link.dart';
import 'package:vitalcare_mobile/vitalcare/view/appointment_detail_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/appointments_view.dart';
import 'package:vitalcare_mobile/vitalcare/view/caregiver_home_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/chat_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/exam_registration_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/first_aid_guide_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/first_aid_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/forgot_password_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/health_sharing_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/health_trends_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/health_view.dart';
import 'package:vitalcare_mobile/vitalcare/view/home_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/login_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/measurement_history_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/measurement_result_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/measurement_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/measuring_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/messages_view.dart';
import 'package:vitalcare_mobile/vitalcare/view/notifications_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/profile_view.dart';
import 'package:vitalcare_mobile/vitalcare/view/shared_health_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/shared_people_view.dart';
import 'package:vitalcare_mobile/vitalcare/view/sign_up_screen.dart';
import 'package:vitalcare_mobile/vitalcare/view/verification_pin_screen.dart';

const _sizes = <String, Size>{
  '320x568': Size(
    320,
    568,
  ), // iPhone SE (1st), the narrowest phone still around
  '360x640': Size(360, 640), // small Android
  '375x667': Size(375, 667), // iPhone SE / 8
  '412x915': Size(412, 915), // large Android
  '844x390': Size(844, 390), // a phone on its side
  '667x375': Size(667, 375), // a small phone on its side
  '600x960': Size(600, 960), // small tablet / unfolded phone
};
const _scales = [1.0, 1.5, 2.0]; // 2.0 checks the app's own clamp holds

// Long on purpose: names, messages and values that make a layout show its seams.
const _name = 'Nguyễn Thị Phương Thảo Bảo Ngọc';
const _clinic = 'Phòng khám Đa khoa VitalCare – Cơ sở Hà Nội';
const _long =
    'Chỉ số SpO₂ của bệnh nhân giảm xuống dưới ngưỡng an toàn trong lần đo gần nhất, vui lòng liên hệ ngay với bác sĩ phụ trách.';
const _at = '2026-11-09T08:30:00Z';

Map<String, Object?> _appointment(String status) => {
  'id': 1,
  'status': status,
  'bookingCode': 'BK20261109001',
  'queueNumber': 127,
  'appointmentDate': '2026-11-10',
  'startTime': '08:30:00',
  'endTime': '09:00:00',
  'reason': 'Theo dõi huyết áp, đau đầu kéo dài và chóng mặt khi đứng dậy',
  'cancelReason': null,
  'paidAt': null,
  'customer': {'id': 1, 'fullName': _name},
  'clinic': {'id': 'c1', 'name': _clinic},
  'doctor': {
    'id': 3,
    'fullName': 'BS. Nguyễn Minh Khoa Trường',
    'specialty': 'Nội tổng quát',
  },
  'examRoom': {'name': 'Phòng khám số 101'},
};

const _profile = {
  'id': 1,
  'self': true,
  'fullName': _name,
  'customerCode': 'KH000037',
  'phone': '0900000501',
  'dateOfBirth': '1991-03-14',
  'gender': 'female',
  'relationship': null,
  'complete': true,
};

const _shared = {
  'permissionId': 1,
  'customerId': 2,
  'fullName': _name,
  'customerCode': 'KH000038',
  'shareVitals': true,
  'shareAlerts': true,
  'shareAppointments': true,
  'expiresAt': null,
};

const _alert = {
  'id': 1,
  'metric': 'SPO2',
  'severity': 'WARNING',
  'status': 'OPEN',
  'message': _long,
  'measuredValue': 91,
  'triggeredAt': _at,
  'lastTriggeredAt': _at,
  'patient': {'customerId': 1, 'fullName': _name},
};

const _article = {
  'id': 1,
  'title': 'Xử trí ban đầu khi người lớn tuổi bị ngất xỉu tại nhà',
  'category': 'fainting',
  'summary': _long,
  'body':
      'Bước một.\n## Khi nào cần gọi cấp cứu\n$_long\n- Đặt nằm nghiêng\n- Theo dõi nhịp thở',
  'emergencyWarning': _long,
  'videoUrl': null,
  'publishedAt': _at,
};

const _conversation = {
  'id': 1,
  'clinicId': 'c1',
  'clinicName': _clinic,
  'clinicPhone': '+84900000000',
  'status': 'open',
  'lastMessageAt': _at,
  'lastMessagePreview': _long,
  'lastSenderKind': 'staff',
  'unread': 12,
  'aboutCustomerId': null,
  'aboutName': null,
};

Object? _body(String path) {
  if (path.startsWith('/api/my_appointments/') && path.endsWith('/queue')) {
    return {
      'ahead': 13,
      'awaitingPayment': true,
      'skipped': false,
      'returned': false,
    };
  }
  if (path.endsWith('/result')) {
    return {
      'encounter': {
        'chiefComplaint': _long,
        'diagnosis': _long,
        'finalConclusion': _long,
        'followUp': _long,
        'clinicalNote': _long,
      },
    };
  }
  if (path.endsWith('/invoice/all')) {
    return [
      {
        'invoice': {
          'id': 9,
          'kind': 'exam',
          'status': 'unpaid',
          'amount': 150000,
          'total': 150000,
        },
        'onlinePayment': true,
      },
    ];
  }
  if (path.contains('/doctors')) {
    return [
      {
        'id': 3,
        'fullName': 'BS. Nguyễn Minh Khoa Trường',
        'specialty': 'Nội tổng quát',
        'professionalTitle': 'BS.',
        'workingHours': [
          {'dayOfWeek': 1},
        ],
        'day': {
          'working': true,
          'remaining': 5,
          'bookable': true,
          'nextNumber': 8,
          'estimatedStart': '09:00:00',
        },
      },
    ];
  }
  if (path.contains('/open-days')) {
    return [
      {'date': '2026-11-11', 'remaining': 4},
    ];
  }
  if (path.startsWith('/api/my_conversations/') &&
      path != '/api/my_conversations/clinics') {
    return {
      'conversation': _conversation,
      'messages': [
        for (var i = 0; i < 6; i++)
          {
            'id': i,
            'mine': i.isEven,
            'senderKind': i.isEven ? 'customer' : 'staff',
            'senderName': _name,
            'text': _long,
            'image': false,
            'sentAt': _at,
            'read': true,
          },
      ],
    };
  }
  if (path.startsWith('/api/public/first_aid/')) return _article;
  if (path.startsWith('/api/my_appointments/')) return _appointment('booked');
  if (path.endsWith('/vitals/latest') || path == '/api/my_vital_signs/latest') {
    return {
      'heartRate': 128,
      'heartRateAt': _at,
      'spo2': 100,
      'spo2At': _at,
      'skinTemperature': 33.4,
      'skinTemperatureAt': _at,
      'bodyTemperature': 36.6,
      'bodyTemperatureAt': _at,
      'lastMeasuredAt': _at,
      'readings24h': 1240,
    };
  }
  return switch (path) {
    '/api/auth/permissions' => {
      'roles': ['patient'],
      'permissions': <String>[],
    },
    '/api/auth/me' => {
      'id': 1,
      'phone': '0900000501',
      'email': 'nguyen.thi.phuong.thao@example.com',
      'fullName': _name,
    },
    '/api/notifications/unread-count' => {'unread': 128},
    '/api/notifications' => [
      for (var i = 0; i < 4; i++)
        {
          'id': i,
          'title': 'Cảnh báo chỉ số SpO₂ thấp của $_name',
          'type': 'alert',
          'level': 'WARNING',
          'body': _long,
          'link': null,
          'read': i > 1,
          'alertId': 1,
          'createdAt': _at,
        },
    ],
    '/api/my_profiles' => [
      _profile,
      {
        ..._profile,
        'id': 2,
        'self': false,
        'relationship': 'parent',
        'complete': false,
        'dateOfBirth': null,
      },
    ],
    '/api/my_appointments' || '/api/shared_patients/2/appointments' => [
      for (final s in [
        'booked',
        'ready_for_examination',
        'in_exam',
        'completed',
        'cancelled',
        'no_show',
      ])
        _appointment(s),
    ],
    '/api/my_appointments/payment-rules' => {'onlinePaymentRequired': false},
    '/api/public/clinics' => [
      {
        'id': 'c1',
        'name': _clinic,
        'address':
            '1 Đường Nguyễn Văn Linh, Phường Tân Phong, Quận 7, TP. Hồ Chí Minh',
        'phone': '+84900000000',
      },
    ],
    '/api/my_vital_signs' => [
      for (var i = 0; i < 8; i++)
        {
          'id': i,
          'measuredAt': _at,
          'heartRate': 128,
          'spo2': 100,
          'skinTemperature': 33.4,
          if (i.isEven) 'bodyTemperature': 36.6,
          'deviceCode': 'VC-WATCH-000123',
        },
    ],
    '/api/my_vital_signs/trend' || '/api/shared_patients/2/vitals/trend' => {
      'unit': 'hour',
      'points': [
        for (var i = 0; i < 24; i++)
          {
            'at': '2026-11-09T${i.toString().padLeft(2, '0')}:00:00',
            'readings': 3,
            'heartRateAvg': 60 + i * 3,
            'spo2Avg': 92 + i % 8,
            'skinTemperatureAvg': 32.5 + i / 10,
            'bodyTemperatureAvg': 36.2 + i / 50,
          },
      ],
    },
    '/api/my_alerts' || '/api/shared_patients/2/alerts' => [_alert, _alert],
    '/api/my_devices' => [
      {
        'deviceId': 1,
        'deviceCode': 'VC-WATCH-000123',
        'deviceType': 'band',
        'model': 'VitalCare Band Pro Max 2',
        'customerId': 1,
        'customerName': _name,
        'connectivity': 'ONLINE',
        'batteryLevel': 8,
        'firmwareVersion': '1.0.12',
        'lastSeenAt': _at,
        'lastSyncAt': _at,
        'pairedAt': _at,
        'pairedWithMe': true,
      },
    ],
    '/api/public/first_aid' => [
      _article,
      {..._article, 'id': 2, 'category': 'fever'},
    ],
    '/api/my_conversations' => [
      _conversation,
      {..._conversation, 'id': 2, 'aboutCustomerId': 2, 'aboutName': _name},
    ],
    '/api/my_conversations/clinics' => ['c1'],
    '/api/my_sharing' => [
      {
        'id': 1,
        'status': 'ACTIVE',
        'customerId': 1,
        'customerName': _name,
        'caregiverName': _name,
        'caregiverPhone': '0912345678',
        'shareVitals': true,
        'shareAlerts': true,
        'shareAppointments': true,
        'emergencyPhone': '0912345678',
        'expiresAt': _at,
      },
    ],
    '/api/shared_patients' => [
      _shared,
      {..._shared, 'permissionId': 2, 'customerId': 3},
    ],
    '/api/emergency_alerts' => [
      {
        'id': 1,
        'alertId': 1,
        'severity': 'CRITICAL',
        'message': _long,
        'customerId': 2,
        'patientName': _name,
        'emergencyPhone': '0912345678',
        'status': 'SENT',
        'notifiedAt': _at,
        'acknowledgedAt': null,
      },
    ],
    _ => <String, Object>{},
  };
}

http.Response _fake(http.Request request) => http.Response.bytes(
  utf8.encode(jsonEncode(_body(request.url.path))),
  200,
  headers: {'content-type': 'application/json', 'x-total-count': '40'},
);

final _screens = <String, Widget Function()>{
  'Đăng nhập': () => const LoginScreen(),
  'Đăng ký': () => const SignUpScreen(),
  'Quên mật khẩu': () => const ForgotPasswordScreen(),
  'Nhập mã': () => const VerificationPinScreen(phoneNumber: '0900000501'),
  'Trang chủ': () => const HomeScreen(),
  'Sức khỏe': () => const Scaffold(body: HealthView()),
  'Xu hướng': () => const HealthTrendsScreen(),
  'Lịch sử đo': () => const MeasurementHistoryScreen(),
  'Đo': () => const MeasurementScreen(),
  'Đang đo': () => const MeasuringScreen(),
  'Kết quả đo': () => MeasurementResultScreen(
    measuredAt: DateTime(2026, 11, 9, 8, 30),
    heartRate: 128.4,
    spo2: 99.6,
    bodyTemperature: 36.64,
    skinTemperature: 34.17,
    bodyUncalibrated: true,
    sync: BandSyncSummary()
      ..segments = 2
      ..accepted = 1240
      ..rejected = 12,
  ),
  'Kết quả đo (chưa lưu)': () => MeasurementResultScreen(
    measuredAt: DateTime(2026, 11, 9, 8, 30),
    skinTemperature: 34.17,
    syncError: const BandException('Bật Bluetooth để kết nối thiết bị đo.'),
  ),
  'Lượt khám': () => const Scaffold(body: AppointmentsView()),
  for (final status in [
    'booked',
    'ready_for_examination',
    'completed',
    'cancelled',
  ])
    'Chi tiết lượt khám ($status)': () => AppointmentDetailScreen(
      appointment: Appointment.fromJson(_appointment(status)),
    ),
  'Đăng ký khám': () => ExamRegistrationScreen(
    profile: Profile.fromJson({
      ..._profile,
      'self': false,
      'relationship': 'parent',
    }),
  ),
  'Tin nhắn': () => const Scaffold(body: MessagesView()),
  'Chat': () =>
      const ChatScreen(clinicId: 'c1', clinicName: _clinic, conversationId: 1),
  'Thông báo': () => const NotificationsScreen(),
  'Cá nhân': () => const Scaffold(body: ProfileView()),
  'Chia sẻ sức khỏe': () => const HealthSharingScreen(),
  'Sơ cứu': () => const FirstAidScreen(),
  'Bài sơ cứu': () => const FirstAidGuideScreen(
    articleId: 1,
    title: 'Xử trí ban đầu khi người lớn tuổi bị ngất xỉu tại nhà',
  ),
  'Người chăm sóc': () => const CaregiverHomeScreen(),
  'Người được chia sẻ': () =>
      Scaffold(body: SharedPeopleView(onPersonSelected: (_) {})),
  'Sức khỏe được chia sẻ': () =>
      SharedHealthScreen(patient: SharedPatient.fromJson(_shared)),
};

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'vc.accessToken': 'access',
      'vc.refreshToken': 'refresh',
      'vc.fullName': _name,
      'vc.phone': '0900000501',
    });
    final store = SessionStore();
    await store.load();
    Api.instance = Api(
      ApiClient(
        httpClient: MockClient((r) async => _fake(r)),
        store: store,
        baseUrl: 'http://api.test/api',
      ),
    );
  });

  for (final MapEntry(key: name, value: build) in _screens.entries) {
    testWidgets('$name vừa mọi cỡ màn hình', (tester) async {
      final overflows = <String>[];
      final previous = FlutterError.onError;
      String where = '';
      FlutterError.onError = (details) {
        final text = details.exceptionAsString();
        if (text.contains('overflowed')) {
          final at = RegExp(
            r'view/([a-z_]+\.dart):(\d+)',
          ).firstMatch(details.toString());
          overflows.add(
            '${at == null ? '?' : '${at[1]}:${at[2]}'} — $where: ${text.split('\n').first}',
          );
        } else {
          previous?.call(details);
        }
      };
      try {
        for (final MapEntry(key: label, value: size) in _sizes.entries) {
          for (final scale in _scales) {
            where = '$label @${scale}x';
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            await tester.pumpWidget(
              MaterialApp(
                key: UniqueKey(),
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF008BA8),
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: clampTextScale(context, child),
                ),
                home: build(),
              ),
            );
            for (var i = 0; i < 6; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          }
        }
        // Gone, so the screen's timers (the measuring countdown, the chat poll) are cancelled.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 20));
      } finally {
        FlutterError.onError = previous;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
      expect(
        overflows.toSet().toList(),
        isEmpty,
        reason: 'Tràn layout ở:\n${overflows.toSet().join('\n')}',
      );
    });
  }
}
