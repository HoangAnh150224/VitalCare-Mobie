import '../api_client.dart';
import '../models.dart';

/// The account's profiles (`/my_profiles`), its visits (`/my_appointments`)
/// and what registering one needs: clinics and their doctors' days.
class AppointmentService {
  AppointmentService(this._client);

  final ApiClient _client;

  Future<List<Profile>> profiles() async => jsonList(
    await _client.get('/my_profiles'),
  ).map(Profile.fromJson).toList();

  /// Newest day first, the account's own visits and its dependants'.
  Future<List<Appointment>> list({int limit = 100}) async => jsonList(
    await _client.get('/my_appointments', query: {'_start': 0, '_end': limit}),
  ).map(Appointment.fromJson).toList();

  Future<Appointment> get(int id) async =>
      Appointment.fromJson(_json(await _client.get('/my_appointments/$id')));

  Future<AppointmentQueue> queue(int id) async => AppointmentQueue.fromJson(
    _json(await _client.get('/my_appointments/$id/queue')),
  );

  /// The doctor's record of a completed visit; a 404 until there is one.
  Future<VisitResult> result(int id) async => VisitResult.fromJson(
    _json(await _client.get('/my_appointments/$id/result')),
  );

  /// Registers a visit with [doctorId] on [date]; the answer carries the queue number.
  Future<Appointment> book({
    int? patientId,
    required int doctorId,
    required DateTime date,
    required String reason,
  }) async => Appointment.fromJson(
    _json(
      await _client.post(
        '/my_appointments',
        body: {
          'patientId': ?patientId,
          'employeeId': doctorId,
          'appointmentDate': isoDay(date),
          'reason': reason,
        },
      ),
    ),
  );

  Future<Appointment> cancel(int id) async => Appointment.fromJson(
    _json(await _client.post('/my_appointments/$id/cancel')),
  );

  /// Moves the visit to another day (and optionally another doctor); it gets a new number.
  Future<Appointment> reschedule(
    int id,
    DateTime date, {
    int? doctorId,
  }) async => Appointment.fromJson(
    _json(
      await _client.post(
        '/my_appointments/$id/reschedule',
        body: {'appointmentDate': isoDay(date), 'employeeId': ?doctorId},
      ),
    ),
  );

  /// Clinics as the public site lists them, with their phone numbers.
  Future<List<Clinic>> clinics() async => jsonList(
    await _client.get('/public/clinics', auth: false),
  ).map(Clinic.fromJson).toList();

  /// A clinic's doctors, each with how [date] looks for them when given.
  Future<List<Doctor>> doctors(String clinicId, {DateTime? date}) async =>
      jsonList(
        await _client.get(
          '/clinics/$clinicId/doctors',
          query: {'date': date == null ? null : isoDay(date)},
        ),
      ).map(Doctor.fromJson).toList();

  static Json _json(Object? body) =>
      body is Map ? body.cast<String, dynamic>() : const {};
}
