import 'package:flutter/material.dart';
import 'first_aid_screen.dart';
import 'health_sharing_screen.dart';
import 'login_screen.dart';
import 'caregiver_home_screen.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

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
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 29,
                        backgroundColor: Color(0xFFDFF3EF),
                        child: Text(
                          'AM',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alex Morgan',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'alex@example.com',
                              style: TextStyle(fontSize: 14, color: _muted),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Bệnh nhân · Hồ sơ mẫu',
                              style: TextStyle(fontSize: 12, color: _primary),
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
                  () => _info(
                    context,
                    'Thông tin cá nhân',
                    'Alex Morgan\nalex@example.com\nVai trò: Bệnh nhân\n\nHồ sơ mẫu. Chức năng chỉnh sửa chưa được tích hợp.',
                  ),
                ),
                _item(
                  'Đổi mật khẩu',
                  Icons.lock_outline_rounded,
                  () => _info(
                    context,
                    'Đổi mật khẩu',
                    'Chức năng đổi mật khẩu chưa được kết nối tài khoản thực tế.',
                  ),
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
                _item(
                  'Thiết bị đã kết nối',
                  Icons.watch_outlined,
                  () => _info(
                    context,
                    'Thiết bị đã kết nối',
                    'Thiết bị VitalCare · Pin 82%\n\nĐây là trạng thái mẫu. Chưa có thiết bị thực tế được kết nối.',
                  ),
                ),
                _item(
                  'Về VitalCare',
                  Icons.info_outline_rounded,
                  () => _info(
                    context,
                    'Về VitalCare',
                    'VitalCare\nỨng dụng theo dõi sức khỏe, lịch hẹn và trao đổi với nhân viên y tế.\n\nBản giao diện thử nghiệm sử dụng dữ liệu mẫu.',
                  ),
                ),
                const SizedBox(height: 6),
                _item(
                  'Xem thử giao diện người thân',
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
