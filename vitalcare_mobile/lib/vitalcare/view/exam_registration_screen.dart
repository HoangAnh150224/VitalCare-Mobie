import 'package:flutter/material.dart';

import '../api/api.dart';
import 'common.dart';

/// Registers a visit: a clinic and a day. The clinic places it with its
/// least-busy doctor that day and gives the next queue number.
///
/// Pops with the created [Appointment].
class ExamRegistrationScreen extends StatefulWidget {
  const ExamRegistrationScreen({super.key, this.profile});

  /// Who the visit is for; null is the account itself.
  final Profile? profile;

  @override
  State<ExamRegistrationScreen> createState() => _ExamRegistrationScreenState();
}

class _ExamRegistrationScreenState extends State<ExamRegistrationScreen> {
  static const _primary = Color(0xFF008C91);
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _birth = TextEditingController();
  final _reason = TextEditingController();
  Profile? _profile;
  DateTime? _date;
  String? _clinicId;
  List<Clinic> _clinics = const [];
  List<Doctor> _doctors = const [];
  bool _loading = true;
  bool _loadingDoctors = false;
  Object? _error;
  bool _saving = false;
  Map<String, String> _serverErrors = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _birth.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = Api.instance.appointments;
      final clinics = await api.clinics();
      final profile = widget.profile ?? await _selfProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _name.text = profile?.fullName ?? '';
        _phone.text = profile?.phone ?? '';
        _birth.text = profile?.dateOfBirth == null
            ? ''
            : _format(profile!.dateOfBirth!);
        _clinics = clinics;
        _clinicId = clinics.length == 1 ? clinics.first.id : null;
      });
      if (_clinicId != null) await _loadDoctors();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Profile?> _selfProfile() async {
    final profiles = await Api.instance.appointments.profiles();
    return profiles.where((p) => p.self).firstOrNull ?? profiles.firstOrNull;
  }

  /// The clinic's doctors, with how the chosen day looks for each; only used
  /// to tell whether the day can be had.
  Future<void> _loadDoctors() async {
    final clinicId = _clinicId;
    if (clinicId == null) return;
    setState(() => _loadingDoctors = true);
    try {
      final doctors = await Api.instance.appointments.doctors(
        clinicId,
        date: _date,
      );
      if (!mounted || clinicId != _clinicId) return;
      setState(() => _doctors = doctors);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  /// Null until a day is chosen and its doctors are loaded.
  bool? get _dayOpen {
    if (_date == null || _loadingDoctors) return null;
    return _doctors.any(
      (d) => d.day != null && d.day!.working && d.day!.bookable,
    );
  }

  String _format(DateTime date) => '${date.day}/${date.month}/${date.year}';

  InputDecoration _decoration(String label, {String? error}) => InputDecoration(
    labelText: label,
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  Future<void> _pickDate() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'Chọn ngày khám',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _date = picked;
      _serverErrors = const {};
    });
    await _loadDoctors();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    final profile = _profile;
    setState(() {
      _saving = true;
      _serverErrors = const {};
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kiểm tra thông tin'),
        content: SingleChildScrollView(
          child: Text(
            '${_name.text}\n${_phone.text}\nNgày sinh: ${_birth.text.isEmpty ? '—' : _birth.text}\n'
            'Phòng khám: ${_clinics.firstWhere((c) => c.id == _clinicId).name}\n'
            'Ngày khám: ${_format(_date!)}\nLý do khám: ${_reason.text.trim()}\n\n'
            'Phòng khám sẽ xếp bạn vào một bác sĩ khám trong ngày; tên bác sĩ và số khám hiện trên phiếu sau khi đăng ký.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Chỉnh sửa'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng ký khám'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _saving = false);
      return;
    }
    try {
      final appointment = await Api.instance.appointments.book(
        patientId: profile == null || profile.self ? null : profile.id,
        clinicId: _clinicId!,
        date: _date!,
        reason: _reason.text.trim(),
      );
      if (mounted) Navigator.pop(context, appointment);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _serverErrors = e.fieldErrors;
      });
      if (e.fieldErrors.isEmpty) showError(context, e);
      // A day can fill up while somebody is looking at it.
      _loadDoctors();
    }
  }

  Widget _dateField() => FormField<DateTime>(
    validator: (_) => _date == null ? 'Vui lòng chọn ngày khám' : null,
    builder: (field) {
      final value = _date;
      final error = field.errorText ?? _serverErrors['appointmentDate'];
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
              await _pickDate();
              if (mounted) field.didChange(_date);
            },
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              value == null ? 'Chọn ngày khám' : 'Ngày khám: ${_format(value)}',
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      );
    },
  );

  Widget _body() {
    if (_loading) return const LoadingBlock();
    if (_error != null) return ErrorBlock(error: _error!, onRetry: _load);
    final incomplete = _profile != null && !_profile!.complete;
    return Form(
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
          const Text('Thông tin lấy từ hồ sơ của người khám.'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            readOnly: true,
            decoration: _decoration('Họ và tên'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            readOnly: true,
            decoration: _decoration('Số điện thoại'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _birth,
            readOnly: true,
            decoration: _decoration(
              'Ngày sinh',
              error: incomplete
                  ? 'Hồ sơ chưa có ngày sinh và giới tính. Vui lòng bổ sung hồ sơ trên trang web VitalCare trước khi đăng ký khám.'
                  : _serverErrors['patientId'],
            ),
          ),
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
          if (_clinics.isEmpty)
            const EmptyBlock(
              icon: Icons.local_hospital_outlined,
              message: 'Hiện chưa có phòng khám nhận đăng ký.',
            ),
          if (_clinics.length > 1) ...[
            DropdownButtonFormField<String>(
              initialValue: _clinicId,
              isExpanded: true,
              decoration: _decoration('Phòng khám'),
              items: _clinics
                  .map(
                    (clinic) => DropdownMenuItem(
                      value: clinic.id,
                      child: Text(clinic.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _clinicId = value;
                  _doctors = const [];
                  _serverErrors = const {};
                });
                _loadDoctors();
              },
              validator: (value) =>
                  value == null ? 'Vui lòng chọn phòng khám' : null,
            ),
            const SizedBox(height: 16),
          ],
          _dateField(),
          const SizedBox(height: 16),
          if (_dayOpen == false)
            Text(
              'Ngày này phòng khám không có bác sĩ khám hoặc đã hết lượt. Vui lòng chọn ngày khác.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else if (_dayOpen == true)
            const Text(
              'Phòng khám sẽ xếp bạn vào một bác sĩ khám trong ngày; tên bác sĩ và số khám hiện trên phiếu sau khi đăng ký.',
              style: TextStyle(color: Color(0xFF657E80), height: 1.5),
            ),
          if (_dayOpen != null) const SizedBox(height: 16),
          TextFormField(
            controller: _reason,
            decoration: _decoration(
              'Lý do khám',
              error: _serverErrors['reason'],
            ),
            maxLength: 255,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Vui lòng nhập lý do khám'
                : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Bạn nhận số thứ tự khám ngay sau khi đăng ký. Giờ khám là giờ dự kiến theo số thứ tự của bác sĩ.',
            style: TextStyle(color: Color(0xFF657E80), height: 1.5),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size.fromHeight(54),
            ),
            onPressed:
                _saving || incomplete || _clinics.isEmpty || _dayOpen == false
                ? null
                : _submit,
            icon: const Icon(Icons.event_available),
            label: Text(_saving ? 'Đang đăng ký...' : 'Đặt lịch khám'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5FAF8),
    appBar: AppBar(
      title: Text(
        widget.profile == null || widget.profile!.self
            ? 'Đăng ký cho chính mình'
            : 'Đăng ký cho người thân',
      ),
      backgroundColor: const Color(0xFFDFF3EF),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _body(),
          ),
        ),
      ),
    ),
  );
}
