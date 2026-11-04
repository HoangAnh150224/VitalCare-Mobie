import '../api_client.dart';
import '../models.dart';

/// The signed-in account's notifications (`/notifications`).
class NotificationService {
  NotificationService(this._client);

  final ApiClient _client;

  Future<List<AppNotification>> list({
    bool unreadOnly = false,
    int limit = 50,
  }) async => jsonList(
    await _client.get(
      '/notifications',
      query: {'_start': 0, '_end': limit, 'read': unreadOnly ? 'unread' : null},
    ),
  ).map(AppNotification.fromJson).toList();

  Future<int> unreadCount() async {
    final body = await _client.get('/notifications/unread-count');
    final value = body is Map ? body['unread'] : null;
    return value is num ? value.toInt() : 0;
  }

  Future<AppNotification> markRead(int id) async => AppNotification.fromJson(
    (await _client.post('/notifications/$id/read') as Map)
        .cast<String, dynamic>(),
  );

  Future<void> markAllRead() => _client.post('/notifications/read-all');
}

/// Published first-aid guidance (`/public/first_aid`), open to everybody.
class FirstAidService {
  FirstAidService(this._client);

  final ApiClient _client;

  Future<List<FirstAidArticle>> list({
    String? query,
    FirstAidCategory? category,
  }) async => jsonList(
    await _client.get(
      '/public/first_aid',
      query: {'q': query, 'category': category?.name},
      auth: false,
    ),
  ).map(FirstAidArticle.fromJson).toList();

  Future<FirstAidArticle> get(int id) async => FirstAidArticle.fromJson(
    (await _client.get('/public/first_aid/$id', auth: false) as Map)
        .cast<String, dynamic>(),
  );
}
