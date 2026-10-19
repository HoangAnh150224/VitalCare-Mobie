import 'package:flutter/material.dart';

class ExamRegistration {
  const ExamRegistration({
    required this.name,
    required this.phone,
    required this.specialty,
    required this.date,
    required this.time,
  });
  final String name;
  final String phone;
  final String specialty;
  final DateTime date;
  final String time;

  String get dateLabel =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class ExamRegistrationScreen extends StatefulWidget {
  const ExamRegistrationScreen({super.key});

  @override
  State<ExamRegistrationScreen> createState() => _ExamRegistrationScreenState();
}

class _ExamRegistrationScreenState extends State<ExamRegistrationScreen> {
  static const _primary = Color(0xFF008C91);
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _birthDate;
  DateTime? _date;
  String? _specialty;
  String? _time;
  bool _saving = false;
  static const _times = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '13:30',
    '14:30',
    '15:30',
  ];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Future<void> _pickDate({bool birth = false}) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: birth
          ? (_birthDate ?? DateTime(now.year - 25))
          : (_date ?? now.add(const Duration(days: 1))),
      firstDate: birth ? DateTime(1900) : now.add(const Duration(days: 1)),
      lastDate: birth ? now : now.add(const Duration(days: 180)),
      helpText: birth ? 'Chọn ngày sinh' : 'Chọn ngày khám',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (birth) {
        _birthDate = picked;
      } else {
        _date = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final registration = ExamRegistration(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      specialty: _specialty!,
      date: _date!,
      time: _time!,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm tra thông tin'),
        content: SingleChildScrollView(
          child: Text(
            '${registration.name}\n${registration.phone}\nNgày sinh: ${_format(_birthDate!)}\n'
            '${registration.specialty}\n${registration.dateLabel} · ${registration.time}\n\n'
            'Đây là lịch khám thử nghiệm, chỉ lưu trong phiên sử dụng hiện tại và chưa gửi đến cơ sở y tế.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chỉnh sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu lịch khám'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == true) {
      Navigator.pop(context, registration);
    } else {
      setState(() => _saving = false);
    }
  }

  Widget _dateField({bool birth = false}) => FormField<DateTime>(
    validator: (_) => (birth ? _birthDate : _date) == null
        ? (birth ? 'Vui lòng chọn ngày sinh' : 'Vui lòng chọn ngày khám')
        : null,
    builder: (field) {
      final value = birth ? _birthDate : _date;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: Colors.white,
              foregroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              await _pickDate(birth: birth);
              if (mounted) field.didChange(birth ? _birthDate : _date);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              value == null
                  ? (birth ? 'Chọn ngày sinh' : 'Chọn ngày khám')
                  : '${birth ? 'Ngày sinh' : 'Ngày khám'}: ${_format(value)}',
            ),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5FAF8),
    appBar: AppBar(
      title: const Text('Đăng ký cho chính mình'),
      backgroundColor: const Color(0xFFDFF3EF),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Thông tin người khám',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF164E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Điền thông tin của bạn để đăng ký khám.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    decoration: _decoration('Họ và tên'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Vui lòng nhập họ và tên'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    decoration: _decoration('Số điện thoại'),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(
                          (value ?? '').replaceAll(RegExp(r'[\s().-]'), ''),
                        )
                        ? null
                        : 'Vui lòng nhập số điện thoại hợp lệ',
                  ),
                  const SizedBox(height: 16),
                  _dateField(birth: true),
                  const SizedBox(height: 28),
                  const Text(
                    'Đặt lịch khám',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF164E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _decoration('Chuyên khoa'),
                    items:
                        [
                              'Khám tổng quát',
                              'Nội khoa',
                              'Tim mạch',
                              'Hô hấp',
                              'Da liễu',
                            ]
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => setState(() => _specialty = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn chuyên khoa' : null,
                  ),
                  const SizedBox(height: 16),
                  _dateField(),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _decoration('Giờ khám'),
                    items: _times
                        .map(
                          (time) =>
                              DropdownMenuItem(value: time, child: Text(time)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _time = value),
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn giờ khám' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Lịch thử nghiệm • Chưa kết nối cơ sở y tế. Khung giờ hiển thị là giờ mẫu.',
                    style: TextStyle(color: Color(0xFF657E80), height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Đặt lịch khám'),
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
