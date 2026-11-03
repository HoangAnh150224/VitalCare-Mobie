import 'package:flutter/material.dart';

import '../api/api.dart';
import 'common.dart';

/// One visit: its number and day, where it stands in today's line, and the
/// doctor's conclusions once it is completed. Pops with `true` after a
/// change, so the list reloads.
class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});
  final Appointment appointment;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  late Appointment _appointment = widget.appointment;
  AppointmentQueue? _queue;
  VisitResult? _result;
  String? _clinicPhone;
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = Api.instance.appointments;
    try {
      final fresh = await api.get(widget.appointment.id);
      if (!mounted) return;
      setState(() => _appointment = fresh);
    } catch (e) {
      if (mounted) showError(context, e);
    }
    final appointment = _appointment;
    await Future.wait([
      if (appointment.status.isActive &&
          appointment.status != AppointmentStatus.scheduled)
        api
            .queue(appointment.id)
            .then((q) => _queue = q)
            .catchError((Object _) => const AppointmentQueue()),
      if (appointment.status == AppointmentStatus.completed)
        api
            .result(appointment.id)
            .then((r) => _result = r)
            // No result yet is a 404; the screen just leaves it out.
            .catchError((Object _) => const VisitResult()),
      api
          .clinics()
          .then((clinics) {
            _clinicPhone = clinics
                .where((c) => c.id == appointment.clinicId)
                .firstOrNull
                ?.phone;
            return clinics;
          })
          .catchError((Object _) => const <Clinic>[]),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  void _notice(String message) => showNotice(context, message);

  Future<void> _contact() async {
    final phone = _clinicPhone;
    if (phone == null || phone.isEmpty) {
      _notice('Phòng khám chưa có số điện thoại liên hệ.');
      return;
    }
    await callPhone(context, phone);
  }

  Future<void> _reschedule() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = _appointment.date ?? today;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      helpText: 'Chọn ngày khám mới',
      cancelText: 'Hủy',
      confirmText: 'Đổi lịch',
    );
    if (date == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final moved = await Api.instance.appointments.reschedule(
        _appointment.id,
        date,
      );
      if (!mounted) return;
      setState(() {
        _appointment = moved;
        _changed = true;
      });
      _notice(
        'Đã đổi lịch sang ngày ${fullDate(date)}. Số thứ tự mới: ${moved.queueLabel}.',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: const Text(
          'Lịch hẹn sẽ bị hủy tại phòng khám và số thứ tự không còn giá trị.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lịch hẹn'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy lịch hẹn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final cancelled = await Api.instance.appointments.cancel(_appointment.id);
      if (!mounted) return;
      setState(() {
        _appointment = cancelled;
        _changed = true;
      });
      _notice('Đã hủy lịch hẹn.');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ],
    ),
  );

  String? get _queueText {
    final queue = _queue;
    if (queue == null) return null;
    if (queue.awaitingPayment) {
      return 'Vui lòng thanh toán phí khám tại quầy để vào hàng chờ.';
    }
    if (queue.skipped) {
      return 'Đã gọi nhưng bạn chưa có mặt. Vui lòng báo lễ tân.';
    }
    if (queue.ahead != null) {
      return queue.ahead == 0
          ? 'Sắp đến lượt bạn.'
          : 'Còn ${queue.ahead} người trước bạn.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final appointment = _appointment;
    final day = appointment.date;
    final date = day == null ? '—' : fullDate(day);
    final expected = appointment.startTime == null
        ? ''
        : ' · dự kiến ${appointment.startTime}';
    final result = _result;
    final changeable = appointment.status == AppointmentStatus.scheduled;
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: _primary,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: Color(0xFFCCDADC)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FBF9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDFF3EF),
          surfaceTintColor: Colors.transparent,
          foregroundColor: _ink,
          centerTitle: true,
          title: const Text(
            'Chi tiết lịch hẹn',
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 30,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appointment.doctorName ?? 'Bác sĩ',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  appointment.clinicName ?? 'Phòng khám',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        appointment.bookingCode == null
                            ? 'Mã lịch hẹn: —'
                            : 'Mã lịch hẹn: ${appointment.bookingCode}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE0ECE9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (appointment.patientName != null)
                              _field('Người khám', appointment.patientName!),
                            _field(
                              'Ngày khám và số thứ tự',
                              '$date · Số ${appointment.queueLabel}$expected',
                            ),
                            _field('Trạng thái', appointment.status.label),
                            if (_queueText != null)
                              _field('Hàng chờ hôm nay', _queueText!),
                            if (appointment.examRoom != null)
                              _field('Phòng khám bệnh', appointment.examRoom!),
                            if (appointment.specialty != null)
                              _field('Chuyên khoa', appointment.specialty!),
                            _field('Lý do khám', appointment.reason ?? '—'),
                            if (appointment.cancelReason != null)
                              _field('Lý do hủy', appointment.cancelReason!),
                            if (result?.diagnosis != null)
                              _field('Chẩn đoán', result!.diagnosis!),
                            if (result?.conclusion != null)
                              _field('Kết luận', result!.conclusion!),
                            if (result?.followUp != null)
                              _field('Hẹn tái khám', result!.followUp!),
                            if (_loading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: LinearProgressIndicator(color: _primary),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: _contact,
                        style: buttonStyle,
                        icon: const Icon(Icons.phone_outlined, size: 20),
                        label: const Text('Liên hệ phòng khám'),
                      ),
                      if (changeable) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _reschedule,
                          style: buttonStyle,
                          icon: const Icon(
                            Icons.edit_calendar_outlined,
                            size: 20,
                          ),
                          label: const Text('Đổi ngày khám'),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _busy ? null : _cancel,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFB24C4C),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text(
                            'Hủy lịch hẹn',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          'Chỉ đổi hoặc hủy được chậm nhất 2 giờ trước giờ khám dự kiến.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
