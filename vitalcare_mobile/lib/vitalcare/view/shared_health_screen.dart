import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

/// What one patient shares with the caregiver: latest readings, alerts and
/// appointments (`/shared_patients/{id}/...`), each only when shared.
class SharedHealthScreen extends StatefulWidget {
  const SharedHealthScreen({super.key, required this.patient});
  final SharedPatient patient;

  @override
  State<SharedHealthScreen> createState() => _SharedHealthScreenState();
}

class _SharedHealthScreenState extends State<SharedHealthScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);

  VitalLatest? _latest;
  List<Alert> _alerts = const [];
  List<Appointment> _appointments = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patient = widget.patient;
    final sharing = Api.instance.sharing;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object?>([
        patient.shareVitals
            ? sharing.latest(patient.customerId)
            : Future.value(null),
        patient.shareAlerts
            ? sharing.alerts(patient.customerId)
            : Future.value(const <Alert>[]),
        patient.shareAppointments
            ? sharing.appointments(patient.customerId)
            : Future.value(const <Appointment>[]),
      ]);
      if (!mounted) return;
      setState(() {
        _latest = results[0] as VitalLatest?;
        _alerts = results[1] as List<Alert>;
        _appointments = results[2] as List<Appointment>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFBDD3CE)),
    ),
    child: child,
  );

  Widget _metric(
    String label,
    String value,
    IconData icon,
    Color color,
    String time,
    VitalMetric metric,
  ) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        const SizedBox(height: 8),
        // The number shrinks to fit its card rather than breaking mid-value on a narrow phone.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value == '--'
              ? 'Chưa có dữ liệu'
              : _alerts.any((a) => a.isOpen && a.vitalMetric == metric)
              ? 'Cần chú ý'
              : 'Bình thường',
          style: TextStyle(
            fontSize: 11,
            color: value == '--'
                ? _muted
                : _alerts.any((a) => a.isOpen && a.vitalMetric == metric)
                ? const Color(0xFF93521C)
                : const Color(0xFF24704F),
          ),
        ),
        const SizedBox(height: 5),
        Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    ),
  );

  Widget _section(String title, String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.6, color: _muted),
          ),
        ],
      ),
    ),
  );

  String get _alertText {
    if (!widget.patient.shareAlerts) return 'Không được chia sẻ.';
    final open = _alerts.where((a) => a.isOpen).toList();
    if (open.isEmpty) return 'Không có cảnh báo nào đang mở.';
    return open
        .take(3)
        .map(
          (a) =>
              '${a.message ?? 'Chỉ số bất thường'}${a.triggeredAt == null ? '' : ' · ${relativeTime(a.triggeredAt!)}'}',
        )
        .join('\n');
  }

  String get _appointmentText {
    if (!widget.patient.shareAppointments) return 'Không được chia sẻ.';
    final now = DateTime.now();
    final upcoming = _appointments.where((a) => a.isUpcoming(now)).toList()
      ..sort((a, b) => (a.date ?? now).compareTo(b.date ?? now));
    if (upcoming.isEmpty) return 'Không có lịch hẹn sắp tới.';
    final next = upcoming.first;
    return [
      if (next.date != null) dayMonth(next.date!),
      'Số ${next.queueLabel}',
      if (next.startTime != null) 'dự kiến ${next.startTime}',
      next.clinicName ?? 'Phòng khám',
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final latest = _latest;
    final name = patient.fullName;
    final firstName = name.trim().split(RegExp(r'\s+')).last;
    final at = latest?.lastMeasuredAt;
    final time = at == null ? ' ' : relativeTime(at);
    final spo2 = latest?.spo2 == null ? '--' : '${decimal(latest!.spo2!)}%';
    final pulse = latest?.heartRate == null ? '--' : '${latest!.heartRate} bpm';
    final body = latest?.bodyTemperature;
    final temperature = body != null
        ? '${decimal(body)}°C'
        : latest?.skinTemperature == null
        ? '--'
        : '${decimal(latest!.skinTemperature!)}°C';
    final expires = patient.expiresAt;
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFF3EF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Sức khỏe được chia sẻ',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDFF3EF), Color(0xFFEEF9F6), Color(0xFFF6FBF9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (patient.customerCode != null)
                      Text(
                        'Mã khách hàng: ${patient.customerCode}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F2ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: _primary,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn chỉ được xem thông tin mà bệnh nhân chia sẻ với bạn.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading) const LoadingBlock(),
                    if (!_loading && _error != null)
                      ErrorBlock(error: _error!, onRetry: _load),
                    if (!_loading && _error == null && patient.shareVitals)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cards = [
                            _metric(
                              'SpO₂',
                              spo2,
                              Icons.water_drop_outlined,
                              const Color(0xFF1F6F8A),
                              time,
                              VitalMetric.spo2,
                            ),
                            _metric(
                              'Nhịp tim',
                              pulse,
                              Icons.favorite_border_rounded,
                              const Color(0xFFB23A48),
                              time,
                              VitalMetric.heartRate,
                            ),
                            _metric(
                              body != null ? 'Nhiệt độ cơ thể' : 'Nhiệt độ da',
                              temperature,
                              Icons.thermostat_rounded,
                              const Color(0xFF8A5A12),
                              time,
                              VitalMetric.skinTemperature,
                            ),
                          ];
                          if (constraints.maxWidth < 320 ||
                              MediaQuery.textScalerOf(context).scale(14) > 19) {
                            return Column(
                              children: [
                                for (final card in cards)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: card,
                                    ),
                                  ),
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < cards.length; i++) ...[
                                if (i > 0) const SizedBox(width: 10),
                                Expanded(child: cards[i]),
                              ],
                            ],
                          );
                        },
                      ),
                    if (!_loading && _error == null) ...[
                      const SizedBox(height: 18),
                      if (patient.shareVitals)
                        _section(
                          at == null
                              ? 'Lần đo gần nhất'
                              : 'Lần đo gần nhất · $time',
                          at == null
                              ? 'Chưa có lần đo nào.'
                              : 'SpO₂ $spo2 · Nhịp tim $pulse · Da $temperature',
                          Icons.history_rounded,
                        ),
                      _section(
                        'Thông báo quan trọng',
                        _alertText,
                        Icons.notifications_none_rounded,
                      ),
                      _section(
                        'Lịch hẹn sắp tới',
                        _appointmentText,
                        Icons.calendar_month_outlined,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      expires == null
                          ? '$firstName chia sẻ · Không giới hạn thời gian'
                          : '$firstName chia sẻ · Đến ${fullDate(expires)}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
