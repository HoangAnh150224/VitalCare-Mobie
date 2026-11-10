import 'package:flutter/material.dart';
import '../api/api.dart';
import 'appointment_detail_screen.dart';
import 'common.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);
  bool _past = false;
  late final DateTime _today = DateTime.now();
  List<Appointment> _appointments = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await Api.instance.appointments.list();
      if (mounted) setState(() => _appointments = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  Future<void> _openDetail(Appointment appointment) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AppointmentDetailScreen(appointment: appointment),
      ),
    );
    if (changed == true && mounted) _load();
  }

  Widget _appointment(Appointment appointment) {
    final date = appointment.date;
    final pending = appointment.status == AppointmentStatus.booked;
    final ended =
        appointment.status == AppointmentStatus.cancelled ||
        appointment.status == AppointmentStatus.noShow;
    final color = pending
        ? const Color(0xFF9A6A18)
        : ended
        ? const Color(0xFFB24C4C)
        : _primary;
    final time = appointment.startTime == null
        ? 'Số ${appointment.queueLabel}'
        : 'Số ${appointment.queueLabel} · dự kiến ${appointment.startTime}';
    final who = appointment.patientName == null
        ? ''
        : ' · ${appointment.patientName}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFBDD3CE)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openDetail(appointment),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF8F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_outlined,
                    color: _primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName ??
                            'Bác sĩ: xếp khi gọi vào phòng',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${appointment.clinicName ?? 'Phòng khám'}$who',
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        date == null ? time : '${_date(date)} · $time',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: pending
                              ? const Color(0xFFFFF5DE)
                              : ended
                              ? const Color(0xFFFBECEC)
                              : const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appointment.status.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _list() {
    if (_loading) return const [LoadingBlock()];
    if (_error != null) return [ErrorBlock(error: _error!, onRetry: _load)];
    final upcoming = _appointments.where((a) => a.isUpcoming(_today)).toList()
      // The nearest visit first.
      ..sort(
        (a, b) => (a.date ?? _today).compareTo(b.date ?? _today) != 0
            ? (a.date ?? _today).compareTo(b.date ?? _today)
            : (a.queueNumber ?? 0).compareTo(b.queueNumber ?? 0),
      );
    final shown = _past
        ? _appointments.where((a) => !a.isUpcoming(_today)).toList()
        : upcoming;
    if (shown.isEmpty) {
      return [
        EmptyBlock(
          icon: Icons.calendar_month_outlined,
          message: _past
              ? 'Chưa có lịch hẹn nào đã qua.'
              : 'Bạn chưa có lịch hẹn sắp tới.',
        ),
      ];
    }
    return [for (final appointment in shown) _appointment(appointment)];
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDFF3EF), Color(0xFFF5FAF8)],
        stops: [0, 0.5],
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Sắp tới')),
                      ButtonSegment(value: true, label: Text('Đã qua')),
                    ],
                    selected: {_past},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        setState(() => _past = value.single),
                    style: ButtonStyle(
                      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? _primary
                            : Colors.white,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (s) => s.contains(WidgetState.selected)
                            ? Colors.white
                            : _ink,
                      ),
                      side: const WidgetStatePropertyAll(
                        BorderSide(color: Color(0xFFA9C1BE)),
                      ),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _past ? 'Lịch hẹn đã qua' : 'Lịch hẹn sắp tới',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                      if (!_loading && _error == null)
                        Text(
                          '${_past ? _appointments.where((a) => !a.isUpcoming(_today)).length : _appointments.where((a) => a.isUpcoming(_today)).length} lịch hẹn',
                          style: const TextStyle(fontSize: 12, color: _muted),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ..._list(),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
