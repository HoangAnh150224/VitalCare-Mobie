import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';
import 'first_aid_screen.dart';
import 'health_sharing_screen.dart';
import 'login_screen.dart';
import 'caregiver_home_screen.dart';

/// The account (`/my_profiles`, the `self` one), its password, its devices
/// (`/my_devices`), sharing, and signing out.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  Profile? _profile;
  bool _caregiver = false;
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
      final api = Api.instance;
      final profiles = await api.appointments.profiles();
      final grants = await api.auth.permissions().catchError(
        (Object _) => const Authorities(),
      );
      if (!mounted) return;
      setState(() {
        _profile =
            profiles.where((p) => p.self).firstOrNull ?? profiles.firstOrNull;
        _caregiver = grants.can('shared_patients:read');
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _name =>
      _profile?.fullName ?? Api.instance.auth.session?.fullName ?? 'Tài khoản';

  String get _phone =>
      _profile?.phone ?? Api.instance.auth.session?.phone ?? '';

  String get _initials {
    final words = _name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';
    final first = words.length > 1 ? words[words.length - 2][0] : '';
    return (first + words.last[0]).toUpperCase();
  }

  String get _personalInfo {
    final profile = _profile;
    final gender = switch (profile?.gender) {
      'male' => 'Nam',
      'female' => 'Nữ',
      'other' => 'Khác',
      _ => '—',
    };
    return [
      _name,
      if (_phone.isNotEmpty) 'Số điện thoại: $_phone',
      'Ngày sinh: ${profile?.dateOfBirth == null ? '—' : fullDate(profile!.dateOfBirth!)}',
      'Giới tính: $gender',
      if (profile?.customerCode != null)
        'Mã khách hàng: ${profile!.customerCode}',
      '',
      'Bạn có thể chỉnh sửa hồ sơ trên trang web VitalCare.',
    ].join('\n');
  }

  void _info(BuildContext context, String title, String content) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (changed == true && mounted) showNotice(context, 'Đã đổi mật khẩu.');
  }

  void _devices() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const _DevicesSheet(),
  );

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ quay lại màn hình đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await Api.instance.auth.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Widget _item(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFB24C4C) : _primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE0ECE9)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Icon(icon, color: color, size: 23),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: danger ? color : _ink,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 21,
            color: danger ? color : _muted,
          ),
          onTap: onTap,
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0ECE9)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 29,
                        backgroundColor: const Color(0xFFDFF3EF),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _phone,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: _error == null ? null : _load,
                              child: Text(
                                _loading
                                    ? 'Đang tải hồ sơ...'
                                    : _error != null
                                    ? 'Không tải được hồ sơ · Chạm để thử lại'
                                    : _profile?.customerCode == null
                                    ? 'Bệnh nhân'
                                    : 'Bệnh nhân · ${_profile!.customerCode}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _item(
                  'Thông tin cá nhân',
                  Icons.person_outline_rounded,
                  () => _info(context, 'Thông tin cá nhân', _personalInfo),
                ),
                _item(
                  'Đổi mật khẩu',
                  Icons.lock_outline_rounded,
                  _changePassword,
                ),
                _item(
                  'Cài đặt thông báo',
                  Icons.notifications_none_rounded,
                  () => _info(
                    context,
                    'Cài đặt thông báo',
                    'Chức năng tùy chỉnh thông báo chưa được tích hợp.',
                  ),
                ),
                _item(
                  'Chia sẻ & quyền riêng tư',
                  Icons.verified_user_outlined,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HealthSharingScreen(),
                    ),
                  ),
                ),
                _item(
                  'Sơ cứu',
                  Icons.medical_services_outlined,
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FirstAidScreen(),
                    ),
                  ),
                ),
                _item('Thiết bị đã kết nối', Icons.watch_outlined, _devices),
                _item(
                  'Về VitalCare',
                  Icons.info_outline_rounded,
                  () => _info(
                    context,
                    'Về VitalCare',
                    'VitalCare\nỨng dụng theo dõi sức khỏe, lịch hẹn và trao đổi với nhân viên y tế.',
                  ),
                ),
                const SizedBox(height: 6),
                if (_caregiver)
                  _item(
                    'Giao diện người thân',
                    Icons.people_outline_rounded,
                    () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CaregiverHomeScreen(),
                      ),
                    ),
                  ),
                _item(
                  'Đăng xuất',
                  Icons.logout_rounded,
                  () => _logout(context),
                  danger: true,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Changes the password; the server answers with a fresh token pair.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  Map<String, String> _errors = const {};
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errors = const {};
      _message = null;
    });
    try {
      await Api.instance.auth.changePassword(_current.text, _next.text);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _errors = e.fieldErrors;
        _message = e.fieldErrors.isEmpty ? e.message : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đổi mật khẩu'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              forceErrorText: _errors['currentPassword'] ?? _message,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu hiện tại',
                errorMaxLines: 3,
              ),
              validator: (value) => (value ?? '').isEmpty
                  ? 'Vui lòng nhập mật khẩu hiện tại.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _next,
              obscureText: true,
              forceErrorText: _errors['newPassword'],
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (value) => (value ?? '').length < 8
                  ? 'Mật khẩu mới phải có từ 8 đến 100 ký tự.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
              validator: (value) =>
                  value != _next.text ? 'Mật khẩu nhập lại không khớp.' : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Đang lưu...' : 'Đổi mật khẩu'),
      ),
    ],
  );
}

/// The bands assigned to the account's profiles, and pairing one with this
/// phone (`POST /my_devices/pair`, `DELETE /my_devices/{code}/pair`).
class _DevicesSheet extends StatefulWidget {
  const _DevicesSheet();

  @override
  State<_DevicesSheet> createState() => _DevicesSheetState();
}

class _DevicesSheetState extends State<_DevicesSheet> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  List<MyDevice> _devices = const [];
  bool _loading = true;
  Object? _error;
  String? _busyCode;

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
      final devices = await Api.instance.devices.list();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(MyDevice device) async {
    setState(() => _busyCode = device.deviceCode);
    try {
      final service = Api.instance.devices;
      final updated = device.pairedWithMe
          ? await service.unpair(device.deviceCode)
          : await service.pair(device.deviceCode);
      if (!mounted) return;
      setState(
        () => _devices = [
          for (final d in _devices)
            d.deviceCode == updated.deviceCode ? updated : d,
        ],
      );
      showNotice(
        context,
        updated.pairedWithMe
            ? 'Đã ghép thiết bị với điện thoại này.'
            : 'Đã hủy ghép thiết bị.',
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busyCode = null);
    }
  }

  String _status(MyDevice device) => [
    device.online ? 'Đang kết nối' : 'Mất kết nối',
    if (device.batteryLevel != null) 'Pin ${device.batteryLevel}%',
    if (device.lastSeenAt != null) 'Lần cuối ${ago(device.lastSeenAt!)}',
    if (device.customerName != null) 'Người đeo: ${device.customerName}',
    device.pairedWithMe
        ? 'Đã ghép với điện thoại này'
        : device.paired
        ? 'Đang ghép với điện thoại khác'
        : 'Chưa ghép điện thoại',
  ].join('\n');

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Thiết bị đã kết nối',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading) const LoadingBlock(),
          if (!_loading && _error != null)
            ErrorBlock(error: _error!, onRetry: _load),
          if (!_loading && _error == null && _devices.isEmpty)
            const EmptyBlock(
              icon: Icons.watch_outlined,
              message: 'Bạn chưa được phòng khám giao thiết bị nào.',
            ),
          if (!_loading)
            for (final device in _devices)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE0ECE9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      device.model == null
                          ? device.deviceCode
                          : '${device.model} · ${device.deviceCode}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status(device),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busyCode != null
                            ? null
                            : () => _toggle(device),
                        style: TextButton.styleFrom(foregroundColor: _primary),
                        child: Text(
                          _busyCode == device.deviceCode
                              ? 'Đang xử lý...'
                              : device.pairedWithMe
                              ? 'Hủy ghép'
                              : 'Ghép với điện thoại này',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    ),
  );
}
