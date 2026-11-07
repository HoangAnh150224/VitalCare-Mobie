import '../api_client.dart';
import '../models.dart';
import '../session_store.dart';

/// `/auth`: signing in and out, the caller's grants, and recovering a
/// forgotten password by SMS (`/auth/password-reset`).
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<bool> hasSession() async => (await _client.store.load()) != null;

  Session? get session => _client.store.current;

  Future<void> login(
    String phone,
    String password, {
    required bool remember,
  }) async {
    final body = await _client.post(
      '/auth/login',
      body: {'phone': phone, 'password': password},
      auth: false,
    );
    final pair = TokenPair.fromJson(
      body is Map ? body.cast<String, dynamic>() : const {},
    );
    await _client.store.save(
      Session(
        accessToken: pair.accessToken,
        refreshToken: pair.refreshToken,
        userId: pair.user?.id,
        fullName: pair.user?.fullName,
        phone: pair.user?.phone ?? phone,
      ),
      persist: remember,
    );
  }

  /// Ends the session on the server too; signing out locally never fails.
  Future<void> logout() async {
    final refresh = _client.store.current?.refreshToken;
    try {
      if (refresh != null) {
        await _client.post(
          '/auth/logout',
          body: {'refreshToken': refresh},
          auth: false,
        );
      }
    } catch (_) {
      // The tokens are dropped below either way.
    } finally {
      await _client.store.clear();
    }
  }

  Future<CurrentUser> me() async => CurrentUser.fromJson(
    (await _client.get('/auth/me') as Map).cast<String, dynamic>(),
  );

  Future<Authorities> permissions() async => Authorities.fromJson(
    (await _client.get('/auth/permissions') as Map).cast<String, dynamic>(),
  );

  /// Changes the password; the server ends other sessions and answers with a
  /// fresh pair for this one.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final body = await _client.post(
      '/auth/change-password',
      body: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
    final pair = TokenPair.fromJson((body as Map).cast<String, dynamic>());
    final current = _client.store.current;
    if (current != null && pair.accessToken.isNotEmpty) {
      await _client.store.save(
        current.copyWith(
          accessToken: pair.accessToken,
          refreshToken: pair.refreshToken,
        ),
      );
    }
  }

  /// Texts a registration code; a number that already has an account is
  /// refused first (UC-04 D2).
  Future<void> requestRegistrationCode(String phone) =>
      _client.post('/auth/register/otp', body: {'phone': phone}, auth: false);

  /// Checks the registration code without spending it and answers with the
  /// profiles the clinic already has with the number, masked (BR-14), for the
  /// person to pick their own. A wrong code is a field error on `otp`.
  Future<List<ProfileMatch>> checkRegistrationCode(
    String phone,
    String otp,
  ) async => jsonList(
    await _client.post(
      '/auth/register/otp/check',
      body: {'phone': phone, 'otp': otp},
      auth: false,
    ),
  ).map(ProfileMatch.fromJson).toList();

  /// Creates the account with the code; [claimProfileId] is the picked
  /// profile, null for "not me". Signs nobody in here: the person signs in next.
  Future<void> register({
    required String phone,
    required String otp,
    required String fullName,
    required String password,
    int? claimProfileId,
  }) => _client.post(
    '/auth/register',
    body: {
      'phone': phone,
      'otp': otp,
      'fullName': fullName,
      'password': password,
      'claimProfileId': claimProfileId,
    },
    auth: false,
  );

  /// Texts a recovery code. Answers the same whether or not the number has an account.
  Future<void> requestResetCode(String phone) => _client.post(
    '/auth/password-reset/otp',
    body: {'phone': phone},
    auth: false,
  );

  /// Checks the code without spending it; a wrong one is a field error on `otp`.
  Future<void> checkResetCode(String phone, String otp) => _client.post(
    '/auth/password-reset/otp/check',
    body: {'phone': phone, 'otp': otp},
    auth: false,
  );

  Future<void> resetPassword(String phone, String otp, String newPassword) =>
      _client.post(
        '/auth/password-reset',
        body: {'phone': phone, 'otp': otp, 'newPassword': newPassword},
        auth: false,
      );
}
