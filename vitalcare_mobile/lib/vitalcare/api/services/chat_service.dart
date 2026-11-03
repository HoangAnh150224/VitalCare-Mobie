import '../api_client.dart';
import '../models.dart';

/// The account's conversations with clinics (`/my_conversations`).
///
/// One conversation per clinic — or, for a caregiver, per clinic and patient:
/// starting one where it exists continues it.
class ChatService {
  ChatService(this._client);

  final ApiClient _client;

  Future<List<Conversation>> list() async =>
      jsonList(await _client.get('/my_conversations')).map(Conversation.fromJson).toList();

  Future<ChatThread> thread(int id) async =>
      ChatThread.fromJson((await _client.get('/my_conversations/$id') as Map).cast<String, dynamic>());

  /// Opens (or continues) the conversation with [clinicId] with a first message.
  Future<ChatThread> start(String clinicId, String text, {int? aboutCustomerId}) async => ChatThread.fromJson(
    (await _client.post(
              '/my_conversations',
              body: {'clinicId': clinicId, 'text': text, 'aboutCustomerId': ?aboutCustomerId},
            )
            as Map)
        .cast<String, dynamic>(),
  );

  Future<ChatLine> send(int conversationId, String text) async => ChatLine.fromJson(
    (await _client.post('/my_conversations/$conversationId/messages', body: {'text': text}) as Map)
        .cast<String, dynamic>(),
  );

  /// The clinics a caregiver may write to about [customerId].
  Future<List<String>> clinicsAbout(int customerId) async {
    final body = await _client.get('/my_conversations/clinics', query: {'aboutCustomerId': customerId});
    return body is List ? body.map((e) => '$e').toList() : const [];
  }

  /// Where an image message is loaded from, with [ApiClient.authHeaders].
  Uri imageUri(int conversationId, int messageId) =>
      _client.uri('/my_conversations/$conversationId/images/$messageId');

  Map<String, String> get imageHeaders => _client.authHeaders;
}

/// Sharing one's health with caregivers (`/my_sharing`), what others share
/// with the caller (`/shared_patients`), and emergency notices
/// (`/emergency_alerts`).
class SharingService {
  SharingService(this._client);

  final ApiClient _client;

  Future<List<SharingPermission>> mine() async =>
      jsonList(await _client.get('/my_sharing')).map(SharingPermission.fromJson).toList();

  Future<SharingPermission> grant({
    int? profileId,
    required String caregiverPhone,
    required String emergencyPhone,
    required bool shareVitals,
    required bool shareAlerts,
    required bool shareAppointments,
    DateTime? expiresAt,
  }) async => SharingPermission.fromJson(
    (await _client.post(
              '/my_sharing',
              body: {
                'profileId': ?profileId,
                'caregiverPhone': caregiverPhone,
                'emergencyPhone': emergencyPhone,
                'shareVitals': shareVitals,
                'shareAlerts': shareAlerts,
                'shareAppointments': shareAppointments,
                'expiresAt': expiresAt == null ? null : isoInstant(expiresAt),
              },
            )
            as Map)
        .cast<String, dynamic>(),
  );

  Future<SharingPermission> update(
    int id, {
    bool? shareVitals,
    bool? shareAlerts,
    bool? shareAppointments,
    DateTime? expiresAt,
  }) async => SharingPermission.fromJson(
    (await _client.put(
              '/my_sharing/$id',
              body: {
                'shareVitals': ?shareVitals,
                'shareAlerts': ?shareAlerts,
                'shareAppointments': ?shareAppointments,
                'expiresAt': expiresAt == null ? null : isoInstant(expiresAt),
              },
            )
            as Map)
        .cast<String, dynamic>(),
  );

  Future<SharingPermission> revoke(int id) async =>
      SharingPermission.fromJson((await _client.post('/my_sharing/$id/revoke') as Map).cast<String, dynamic>());

  Future<List<SharedPatient>> sharedWithMe() async =>
      jsonList(await _client.get('/shared_patients')).map(SharedPatient.fromJson).toList();

  Future<VitalLatest> latest(int customerId) async => VitalLatest.fromJson(
    (await _client.get('/shared_patients/$customerId/vitals/latest') as Map).cast<String, dynamic>(),
  );

  Future<List<Alert>> alerts(int customerId) async =>
      jsonList(await _client.get('/shared_patients/$customerId/alerts')).map(Alert.fromJson).toList();

  Future<List<Appointment>> appointments(int customerId) async =>
      jsonList(await _client.get('/shared_patients/$customerId/appointments')).map(Appointment.fromJson).toList();

  Future<List<EmergencyNotice>> emergencies() async =>
      jsonList(await _client.get('/emergency_alerts')).map(EmergencyNotice.fromJson).toList();

  Future<EmergencyNotice> acknowledge(int id) async => EmergencyNotice.fromJson(
    (await _client.post('/emergency_alerts/$id/acknowledge') as Map).cast<String, dynamic>(),
  );
}
