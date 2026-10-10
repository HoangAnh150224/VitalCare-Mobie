import 'package:flutter/material.dart';

class AppointmentDetailScreen extends StatefulWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.doctor,
    required this.date,
    required this.time,
    required this.status,
    this.isPast = false,
  });
  final String doctor;
  final DateTime date;
  final String time;
  final String status;
  final bool isPast;

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reschedule() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: widget.date.isBefore(today) ? today : widget.date,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      helpText: 'Chọn ngày đề nghị',
      cancelText: 'Hủy',
      confirmText: 'Tiếp tục',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: 'Chọn giờ đề nghị',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (time == null || !mounted) return;
    _notice(
      'Đã chọn ${date.day}/${date.month} · ${time.format(context)}. Đây là lịch mẫu, chưa gửi yêu cầu đến phòng khám.',
    );
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch hẹn?'),
        content: const Text(
          'Đây là lịch hẹn mẫu. Thao tác này chưa hủy lịch thực tế tại phòng khám.',
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
    if (confirmed == true && mounted) {
      _notice(
        'Chưa thể hủy lịch mẫu. Chức năng này cần kết nối với phòng khám.',
      );
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

  @override
  Widget build(BuildContext context) {
    final date =
        '${widget.date.day.toString().padLeft(2, '0')}/${widget.date.month.toString().padLeft(2, '0')}/${widget.date.year}';
    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: _primary,
      backgroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      side: const BorderSide(color: Color(0xFFCCDADC)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
    return Scaffold(
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
                                widget.doctor,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Phòng khám Trung Tâm',
                                style: TextStyle(fontSize: 15, color: _muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lịch hẹn mẫu',
                      style: TextStyle(fontSize: 12, color: _muted),
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
                          _field('Ngày và giờ', '$date · ${widget.time}'),
                          _field('Trạng thái', widget.status),
                          _field(
                            'Lý do khám',
                            'Trao đổi về các kết quả đo gần đây',
                          ),
                          _field('Ghi chú', 'Vui lòng đến sớm 10 phút.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    OutlinedButton.icon(
                      onPressed: () => _notice(
                        'Chưa có số điện thoại hoặc thông tin liên hệ của phòng khám.',
                      ),
                      style: buttonStyle,
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      label: const Text('Liên hệ phòng khám'),
                    ),
                    if (!widget.isPast) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _reschedule,
                        style: buttonStyle,
                        icon: const Icon(
                          Icons.edit_calendar_outlined,
                          size: 20,
                        ),
                        label: const Text('Đề nghị đổi lịch'),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: _cancel,
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
                    ],
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
