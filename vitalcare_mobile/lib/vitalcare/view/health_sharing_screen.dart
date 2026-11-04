import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

/// Sharing one's health with up to two caregivers (`/my_sharing`): who, what,
/// until when, and whom to call in an emergency; and revoking it.
class HealthSharingScreen extends StatefulWidget {
  const HealthSharingScreen({super.key});

  @override
  State<HealthSharingScreen> createState() => _HealthSharingScreenState();
}

class _HealthSharingScreenState extends State<HealthSharingScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _options = [
    'Chỉ số sức khỏe và các lần đo gần đây',
    'Thông báo sức khỏe quan trọng',
    'Lịch hẹn',
  ];
  final Set<int> _selected = {0, 1};
  final _form = GlobalKey<FormState>();
  final _recipient = TextEditingController();
  final _emergency = TextEditingController();
  late DateTime _until = DateTime.now().add(const Duration(days: 14));
  List<SharingPermission> _shares = const [];
  bool _loading = true;
  Object? _error;
  bool _saving = false;
  int? _revoking;
  Map<String, String> _serverErrors = const {};

  String get _date =>
      '${_until.day.toString().padLeft(2, '0')}/${_until.month.toString().padLeft(2, '0')}/${_until.year}';
  String get _who =>
      _recipient.text.trim().isEmpty ? 'người nhận' : _recipient.text.trim();
  String get _summary => _selected.isEmpty
      ? 'Chọn ít nhất một loại thông tin để chia sẻ.'
      : 'Bạn chia sẻ ${(_selected.toList()..sort()).map((i) => _options[i].toLowerCase()).join(', ')} với $_who đến ngày $_date.';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _recipient.dispose();
    _emergency.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shares = await Api.instance.sharing.mine();
      if (mounted) setState(() => _shares = shares);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(SharingPermission share) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thu hồi chia sẻ?'),
        content: Text(
          '${share.caregiverName ?? share.caregiverPhone ?? 'Người này'} sẽ không xem được thông tin sức khỏe của bạn nữa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ chia sẻ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _revoking = share.id);
    try {
      await Api.instance.sharing.revoke(share.id);
      if (!mounted) return;
      showNotice(context, 'Đã thu hồi chia sẻ.');
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _revoking = null);
    }
  }

  InputDecoration _decoration(String hint, IconData icon, String field) =>
      InputDecoration(
        hintText: hint,
        errorText: _serverErrors[field],
        errorMaxLines: 3,
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFCCDADC)),
        ),
      );

  static String? _phoneRule(String? value) {
    final phone = (value ?? '').replaceAll(RegExp(r'[\s().-]'), '');
    if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
    return RegExp(r'^(0\d{9}|\+84\d{9})$').hasMatch(phone)
        ? null
        : 'Số điện thoại không hợp lệ';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _until.isBefore(today) ? today : _until,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Chia sẻ đến ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date != null && mounted) setState(() => _until = date);
  }

  Future<void> _confirm() async {
    if (_selected.isEmpty || _saving) return;
    setState(() => _serverErrors = const {});
    if (!_form.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận chia sẻ'),
        content: SingleChildScrollView(
          child: Text(
            '$_summary\n\nKhi khẩn cấp, hệ thống sẽ liên hệ số ${_emergency.text.trim()}.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chia sẻ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await Api.instance.sharing.grant(
        caregiverPhone: _recipient.text.replaceAll(RegExp(r'[\s().-]'), ''),
        emergencyPhone: _emergency.text.replaceAll(RegExp(r'[\s().-]'), ''),
        shareVitals: _selected.contains(0),
        shareAlerts: _selected.contains(1),
        shareAppointments: _selected.contains(2),
        // Access lasts through the chosen day.
        expiresAt: DateTime(_until.year, _until.month, _until.day, 23, 59, 59),
      );
      if (!mounted) return;
      showNotice(context, 'Đã chia sẻ sức khỏe với $_who.');
      _recipient.clear();
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.fieldErrors);
      if (e.fieldErrors.isEmpty ||
          !e.fieldErrors.keys.any(
            (k) => k == 'caregiverPhone' || k == 'emergencyPhone',
          )) {
        showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _shareLine(SharingPermission share) => [
    if (share.shareVitals) 'chỉ số',
    if (share.shareAlerts) 'thông báo quan trọng',
    if (share.shareAppointments) 'lịch hẹn',
  ].join(', ');

  Widget _current() {
    if (_loading) return const LoadingBlock();
    if (_error != null) return ErrorBlock(error: _error!, onRetry: _load);
    final active = _shares.where((s) => s.active).toList();
    if (active.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Bạn chưa chia sẻ với ai.',
          style: TextStyle(fontSize: 14, color: _muted),
        ),
      );
    }
    return Column(
      children: [
        for (final share in active)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0ECE9)),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.person_outline_rounded,
                color: _primary,
              ),
              title: Text(
                share.caregiverName ?? share.caregiverPhone ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              subtitle: Text(
                '${_shareLine(share)}${share.expiresAt == null ? '' : ' · đến ${fullDate(share.expiresAt!)}'}',
              ),
              trailing: TextButton(
                onPressed: _revoking == null ? () => _revoke(share) : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFB24C4C),
                ),
                child: Text(_revoking == share.id ? '...' : 'Thu hồi'),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6FBF9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFDFF3EF),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      centerTitle: true,
      title: const Text(
        'Chia sẻ sức khỏe',
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
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Đang chia sẻ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _current(),
                    const SizedBox(height: 24),
                    const Text(
                      'Bạn muốn chia sẻ với ai?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _recipient,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(
                        'Số điện thoại người nhận',
                        Icons.person_outline_rounded,
                        'caregiverPhone',
                      ),
                      onChanged: (_) => setState(() {
                        _serverErrors = const {};
                      }),
                      validator: _phoneRule,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Người nhận cần có tài khoản VitalCare. Bạn chia sẻ được tối đa với 2 người.',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emergency,
                      keyboardType: TextInputType.phone,
                      decoration: _decoration(
                        'Số điện thoại liên hệ khẩn cấp',
                        Icons.phone_in_talk_outlined,
                        'emergencyPhone',
                      ),
                      validator: _phoneRule,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chọn thông tin muốn chia sẻ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE0ECE9)),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < _options.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: Color(0xFFE0ECE9),
                              ),
                            CheckboxListTile(
                              value: _selected.contains(i),
                              onChanged: (value) => setState(() {
                                if (value == true) {
                                  _selected.add(i);
                                } else {
                                  _selected.remove(i);
                                }
                              }),
                              activeColor: _primary,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              title: Text(
                                _options[i],
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Chia sẻ đến ngày',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _pickDate,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _ink,
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Color(0xFFCCDADC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            color: _primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _date,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          const Icon(Icons.expand_more_rounded, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F2ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _summary,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _selected.isEmpty || _saving ? null : _confirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.share_outlined, size: 20),
                      label: Text(
                        _saving ? 'Đang chia sẻ...' : 'Xác nhận chia sẻ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
