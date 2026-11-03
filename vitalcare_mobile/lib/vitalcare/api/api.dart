import 'api_client.dart';
import 'services/appointment_service.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/health_service.dart';
import 'services/notification_service.dart';

export 'api_exception.dart';
export 'models.dart';

/// The app's one API client and the services built on it.
///
/// Screens read [Api.instance]; tests replace it with one whose client sends
/// to a `MockClient`.
class Api {
  Api(this.client)
    : auth = AuthService(client),
      appointments = AppointmentService(client),
      health = HealthService(client),
      devices = DeviceService(client),
      notifications = NotificationService(client),
      firstAid = FirstAidService(client),
      chat = ChatService(client),
      sharing = SharingService(client);

  static Api instance = Api(ApiClient());

  final ApiClient client;
  final AuthService auth;
  final AppointmentService appointments;
  final HealthService health;
  final DeviceService devices;
  final NotificationService notifications;
  final FirstAidService firstAid;
  final ChatService chat;
  final SharingService sharing;
}
