import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalcare_mobile/vitalcare/api/api_client.dart';
import 'package:vitalcare_mobile/vitalcare/api/api_exception.dart';
import 'package:vitalcare_mobile/vitalcare/api/session_store.dart';

http.Response json(Object body, int status, {Map<String, String>? headers}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json', ...?headers},
    );

void main() {
  late SessionStore store;
  late List<http.Request> sent;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SessionStore();
    sent = [];
    await store.save(
      const Session(accessToken: 'access-1', refreshToken: 'refresh-1'),
      persist: true,
    );
  });

  ApiClient client(FutureOr<http.Response> Function(http.Request) handler) =>
      ApiClient(
        httpClient: MockClient((request) async {
          sent.add(request);
          return handler(request);
        }),
        store: store,
        baseUrl: 'http://api.test/api',
      );

  group('refresh on 401', () {
    test(
      'trades the refresh token once and retries with the new one',
      () async {
        final api = client((request) {
          if (request.url.path == '/api/auth/refresh') {
            expect(jsonDecode(request.body), {'refreshToken': 'refresh-1'});
            return json({
              'accessToken': 'access-2',
              'refreshToken': 'refresh-2',
            }, 200);
          }
          return request.headers['Authorization'] == 'Bearer access-2'
              ? json([], 200, headers: {'x-total-count': '0'})
              : json({'message': 'Authentication is required'}, 401);
        });

        final response = await api.send('GET', '/my_appointments');

        expect(response.body, isEmpty);
        expect(response.totalCount, 0);
        expect(sent.map((r) => r.url.path), [
          '/api/my_appointments',
          '/api/auth/refresh',
          '/api/my_appointments',
        ]);
        expect(store.current!.accessToken, 'access-2');
        // The new pair is what the next launch reads.
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('vc.refreshToken'), 'refresh-2');
      },
    );

    test('concurrent 401s share one refresh', () async {
      var refreshes = 0;
      final api = client((request) async {
        if (request.url.path == '/api/auth/refresh') {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return json({
            'accessToken': 'access-2',
            'refreshToken': 'refresh-2',
          }, 200);
        }
        return request.headers['Authorization'] == 'Bearer access-2'
            ? json({'ok': true}, 200)
            : json({'message': 'Authentication is required'}, 401);
      });

      await Future.wait([
        api.get('/my_profiles'),
        api.get('/my_devices'),
        api.get('/notifications/unread-count'),
      ]);

      expect(refreshes, 1);
    });

    test('a refused refresh signs out and says so in Vietnamese', () async {
      var expired = 0;
      final api = client(
        (request) => request.url.path == '/api/auth/refresh'
            ? json({'message': 'Refresh token is invalid'}, 401)
            : json({'message': 'Authentication is required'}, 401),
      )..onSessionExpired = () => expired++;

      await expectLater(
        api.get('/my_profiles'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 401)
              .having(
                (e) => e.message,
                'message',
                ApiException.sessionExpiredMessage,
              ),
        ),
      );
      expect(expired, 1);
      expect(store.current, isNull);
      expect(await store.load(), isNull);
    });

    test('an unreachable server during refresh keeps the session', () async {
      final api = client((request) {
        if (request.url.path == '/api/auth/refresh') {
          throw http.ClientException('connection refused');
        }
        return json({'message': 'Authentication is required'}, 401);
      });

      await expectLater(
        api.get('/my_profiles'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetwork, 'network', true),
        ),
      );
      expect(store.current!.refreshToken, 'refresh-1');
    });

    test('calls without auth are neither signed nor refreshed', () async {
      final api = client(
        (request) =>
            json({'message': 'Incorrect phone number or password'}, 401),
      );

      await expectLater(
        api.post(
          '/auth/login',
          body: {'phone': '0901234567', 'password': 'x'},
          auth: false,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Số điện thoại hoặc mật khẩu không đúng.',
          ),
        ),
      );
      expect(sent, hasLength(1));
      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('error parsing', () {
    test('a 422 headlines its first field message, translated', () async {
      final api = client(
        (_) => json({
          'status': 422,
          'message': 'Validation failed',
          'errors': {
            'phone':
                'Phone number must be a Vietnamese number, such as 0901234567 or +84901234567',
            'otp': 'The code is incorrect or has expired',
          },
        }, 422),
      );

      try {
        await api.post('/auth/password-reset/otp/check', auth: false);
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.status, 422);
        expect(e.message, startsWith('Số điện thoại không hợp lệ.'));
        expect(e.field('otp'), 'Mã xác nhận không đúng hoặc đã hết hạn.');
        expect(e.serverMessage, 'Validation failed');
      }
    });

    test('a 409 message is translated by its prefix', () async {
      final api = client(
        (_) => json({
          'message': 'Please wait 42 seconds before asking for another code',
        }, 409),
      );

      await expectLater(
        api.post('/auth/password-reset/otp', auth: false),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            startsWith('Vừa gửi mã cho số này.'),
          ),
        ),
      );
    });

    test('an unknown message is kept, a 5xx is generic, a 404 is worded', () {
      expect(
        ApiException.fromBody(409, {'message': 'Something new'}).message,
        'Something new',
      );
      expect(
        ApiException.fromBody(500, {'message': 'NullPointerException'}).message,
        'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.',
      );
      expect(
        ApiException.fromBody(404, {
          'message': 'Appointment with id 9 was not found',
        }).isNotFound,
        isTrue,
      );
      expect(
        ApiException.fromBody(403, null).message,
        contains('không có quyền'),
      );
    });

    test('a body that is not JSON still gives a Vietnamese error', () async {
      final api = client((_) => http.Response('<html>Bad gateway</html>', 502));

      await expectLater(
        api.get('/my_profiles'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 502)
              .having((e) => e.message, 'message', contains('Máy chủ')),
        ),
      );
    });

    test('a network failure is reported as one', () async {
      final api = client((_) => throw http.ClientException('offline'));

      await expectLater(
        api.get('/my_profiles'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isNetwork, 'network', isTrue)
              .having((e) => e.message, 'message', ApiException.networkMessage),
        ),
      );
    });
  });

  test('query parameters drop nulls and the body is UTF-8 JSON', () async {
    final api = client((_) => json({'id': 1}, 201));

    await api.send(
      'POST',
      '/my_conversations',
      query: {'a': 1, 'b': null},
      body: {'text': 'Chào bác sĩ'},
    );

    expect(sent.single.url.queryParameters, {'a': '1'});
    expect(sent.single.headers['Authorization'], 'Bearer access-1');
    expect(jsonDecode(utf8.decode(sent.single.bodyBytes)), {
      'text': 'Chào bác sĩ',
    });
  });
}
