import 'package:flutter/material.dart';
import 'appointment_detail_screen.dart';

class AppointmentsView extends StatefulWidget {
  const AppointmentsView({super.key});

  @override
  State<AppointmentsView> createState() => _AppointmentsViewState();
}

class _AppointmentsViewState extends State<AppointmentsView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  bool _past = false;
  late final DateTime _today = DateTime.now();

  String _date(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

  Widget _appointment(
    String doctor,
    int dayOffset,
    String time,
    String status,
    bool pending,
  ) {
    final date = DateTime(_today.year, _today.month, _today.day + dayOffset);
    final color = pending ? const Color(0xFF9A6A18) : _primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE0ECE9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AppointmentDetailScreen(
                doctor: doctor,
                date: date,
                time: time,
                status: status,
                isPast: _past,
              ),
            ),
          ),
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
                        doctor,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Phòng khám Trung Tâm',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${_date(date)} · $time',
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
                              : const Color(0xFFE8F5EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
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
      child: SingleChildScrollView(
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
                      BorderSide(color: Color(0xFFCCDADC)),
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
                    const Text(
                      'Dữ liệu mẫu',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!_past) ...[
                  _appointment('BS. Taylor', 2, '10:30', 'Đã xác nhận', false),
                  _appointment('BS. Jordan', 9, '09:00', 'Chờ xác nhận', true),
                ] else ...[
                  _appointment('BS. Taylor', -7, '10:30', 'Đã hoàn tất', false),
                  _appointment(
                    'BS. Jordan',
                    -21,
                    '09:00',
                    'Đã hoàn tất',
                    false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
