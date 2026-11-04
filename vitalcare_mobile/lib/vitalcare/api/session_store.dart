import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in account's tokens and a little about who it is.
class Session {
  const Session({
    required this.accessToken,
    required this.refreshToken,
    this.userId,
    this.fullName,
    this.phone,
  });

  final String accessToken;
  final String refreshToken;
  final int? userId;
  final String? fullName;
  final String? phone;

  Session copyWith({String? accessToken, String? refreshToken}) => Session(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    userId: userId,
    fullName: fullName,
    phone: phone,
  );
}

/// Keeps the session in memory and, when the user asked to be remembered,
/// in shared preferences so the next launch skips the login screen.
///
/// The refresh token is single-use on the server, so every refresh must be
/// written back here — [save] keeps the persistence choice made at login.
class SessionStore {
  SessionStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  static const _accessKey = 'vc.accessToken';
  static const _refreshKey = 'vc.refreshToken';
  static const _userIdKey = 'vc.userId';
  static const _nameKey = 'vc.fullName';
  static const _phoneKey = 'vc.phone';

  final Future<SharedPreferences> Function() _preferences;
  Session? _session;
  bool _persist = false;

  Session? get current => _session;

  /// Reads a remembered session from disk. A storage failure is no session.
  Future<Session?> load() async {
    if (_session != null) return _session;
    try {
      final prefs = await _preferences();
      final access = prefs.getString(_accessKey);
      final refresh = prefs.getString(_refreshKey);
      if (access == null || refresh == null) return null;
      _persist = true;
      return _session = Session(
        accessToken: access,
        refreshToken: refresh,
        userId: prefs.getInt(_userIdKey),
        fullName: prefs.getString(_nameKey),
        phone: prefs.getString(_phoneKey),
      );
    } catch (_) {
      return null;
    }
  }

  /// Stores [session]. [persist] is decided at login; a refresh passes null
  /// to keep that decision.
  Future<void> save(Session session, {bool? persist}) async {
    _session = session;
    if (persist != null) _persist = persist;
    try {
      final prefs = await _preferences();
      if (!_persist) {
        await _remove(prefs);
        return;
      }
      await prefs.setString(_accessKey, session.accessToken);
      await prefs.setString(_refreshKey, session.refreshToken);
      if (session.userId != null) {
        await prefs.setInt(_userIdKey, session.userId!);
      }
      if (session.fullName != null) {
        await prefs.setString(_nameKey, session.fullName!);
      }
      if (session.phone != null) {
        await prefs.setString(_phoneKey, session.phone!);
      }
    } catch (_) {
      // The in-memory session still works for this run.
    }
  }

  Future<void> clear() async {
    _session = null;
    _persist = false;
    try {
      await _remove(await _preferences());
    } catch (_) {
      // Nothing more to do: memory is already cleared.
    }
  }

  Future<void> _remove(SharedPreferences prefs) async {
    for (final key in [
      _accessKey,
      _refreshKey,
      _userIdKey,
      _nameKey,
      _phoneKey,
    ]) {
      await prefs.remove(key);
    }
  }
}
