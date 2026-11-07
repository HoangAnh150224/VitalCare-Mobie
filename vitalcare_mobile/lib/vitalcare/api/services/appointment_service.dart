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

  /// Registers a visit at [clinicId] on [date]; the clinic places it with its
  /// least-busy doctor that day and the answer carries the doctor and number.
  Future<Appointment> book({
    int? patientId,
    required String clinicId,
    required DateTime date,
    required String reason,
  }) async => Appointment.fromJson(
    _json(
      await _client.post(
        '/my_appointments',
        body: {
          'patientId': ?patientId,
          'appointmentDate': isoDay(date),
          'reason': reason,
          'clinicId': clinicId,
        },
      ),
    ),
  );

  Future<Appointment> cancel(int id) async => Appointment.fromJson(
    _json(await _client.post('/my_appointments/$id/cancel')),
  );

  /// Moves the visit to another day; the clinic keeps the doctor when they
  /// have a turn left, else places it with another. It gets a new number.
  Future<Appointment> reschedule(int id, DateTime date) async =>
      Appointment.fromJson(
        _json(
          await _client.post(
            '/my_appointments/$id/reschedule',
            body: {'appointmentDate': isoDay(date)},
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

  /// The next days from [from] with a place left at the clinic, for a day
  /// that is full: what to pick instead. Online and walk-in visits share them.
  Future<List<({DateTime date, int remaining})>> openDays(
    String clinicId, {
    required DateTime from,
  }) async =>
      jsonList(
            await _client.get(
              '/clinics/$clinicId/open-days',
              query: {'from': isoDay(from), 'days': 5},
            ),
          )
          .map(
            (day) => (
              date: DateTime.parse(day['date'] as String),
              remaining: (day['remaining'] as num).toInt(),
            ),
          )
          .toList();

  /// The visit's examination bill as the portal shows it: its id, whether it
  /// is paid, and whether it can be paid online (VNPay). Null when it has none.
  Future<({int id, bool paid, bool online})?> examBill(
    int appointmentId,
  ) async {
    for (final own in jsonList(
      await _client.get('/my_appointments/$appointmentId/invoice/all'),
    )) {
      final invoice = _json(own['invoice']);
      if (invoice['kind'] == 'service' || invoice['status'] == 'cancelled') {
        continue;
      }
      return (
        id: (invoice['id'] as num).toInt(),
        paid: invoice['status'] == 'paid',
        online: own['onlinePayment'] == true,
      );
    }
    return null;
  }

  /// BR-11: after three no-shows the account pays online; the desk is not offered.
  Future<bool> onlinePaymentRequired() async =>
      _json(
        await _client.get('/my_appointments/payment-rules'),
      )['onlinePaymentRequired'] ==
      true;

  /// Where to pay [invoiceId] with VNPay; the API sends the browser back to the portal.
  Future<String> vnpayUrl(int invoiceId) async =>
      _json(await _client.post('/my_invoices/$invoiceId/vnpay'))['url']
          as String;

  static Json _json(Object? body) =>
      body is Map ? body.cast<String, dynamic>() : const {};
}
