import 'package:flutter/material.dart';
import 'messages_view.dart';
import 'notifications_screen.dart';
import 'shared_people_view.dart';
import 'shared_health_screen.dart';

class CaregiverHomeScreen extends StatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  State<CaregiverHomeScreen> createState() => _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends State<CaregiverHomeScreen> {
  static const _ink = Color(0xFF164E50);
  static const _teal = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  int _tab = 0;
  int _person = 0;

  void _health(int index) {
    setState(() => _person = index);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedHealthScreen(personIndex: index),
      ),
    );
  }

  Widget _card(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0ECE9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(icon, color: _teal, size: 25),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, height: 1.5, color: _muted),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: _muted,
          size: 20,
        ),
        onTap: onTap,
      ),
    ),
  );

  Future<void> _notifications() async {
    final tab = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(showNavigation: false),
      ),
    );
    if (!mounted || tab == null) return;
    // The existing notifications screen returns patient-navigation indices.
    setState(
      () => _tab = switch (tab) {
        0 => 0,
        1 => 1,
        3 => 2,
        4 => 4,
        _ => 0,
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6FBF9),
    appBar: AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFDFF3EF),
      foregroundColor: _ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        ['Trang chủ', 'Người chia sẻ', 'Tin nhắn', 'Thông báo', 'Thêm'][_tab],
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
    ),
    body: _tab == 1
        ? SharedPeopleView(onPersonSelected: _health)
        : _tab == 2
        ? const MessagesView()
        : Container(
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
                        if (_tab == 4) ...[
                          const Text(
                            'Sam Morgan',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Người thân · Hồ sơ mẫu',
                            style: TextStyle(color: _muted),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            'Về giao diện bệnh nhân',
                            'Kết thúc xem thử giao diện người thân',
                            Icons.swap_horiz_rounded,
                            () => Navigator.pop(context),
                          ),
                        ] else ...[
                          Text(
                            _tab == 0
                                ? 'Chào buổi sáng, Sam'
                                : 'Sức khỏe được chia sẻ',
                            style: const TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '2 người đang chia sẻ sức khỏe với bạn.',
                            style: TextStyle(fontSize: 14, color: _muted),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bản xem thử · Dữ liệu mẫu',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                          const SizedBox(height: 20),
                          _card(
                            'Alex Morgan · Cha/mẹ',
                            'Lần đo hôm nay · Xem sức khỏe',
                            Icons.person_outline_rounded,
                            () => _health(0),
                          ),
                          _card(
                            'Casey Morgan · Người thân',
                            'Lần đo hôm nay · Xem sức khỏe',
                            Icons.person_outline_rounded,
                            () => _health(1),
                          ),
                          if (_tab == 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () => _health(_person),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _teal,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Xem sức khỏe'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setState(() => _tab = 2),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: _teal,
                                      minimumSize: const Size.fromHeight(52),
                                      side: const BorderSide(
                                        color: Color(0xFFCCDADC),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text('Tin nhắn'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _card(
                              'Cập nhật quan trọng · Alex Morgan',
                              'Cập nhật sức khỏe mới · 10 phút trước',
                              Icons.favorite_border_rounded,
                              () => _health(0),
                            ),
                            _card(
                              'Tin nhắn từ Jamie Lee',
                              'Tôi có thể giúp gì? · 09:30',
                              Icons.chat_bubble_outline_rounded,
                              () => setState(() => _tab = 2),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFDFF3EF),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: const WidgetStatePropertyAll(
        TextStyle(fontSize: 11, color: _ink),
      ),
      onDestinationSelected: (index) {
        if (index == 3) {
          _notifications();
        } else {
          setState(() => _tab = index);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Trang chủ',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          label: 'Được chia sẻ',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          label: 'Tin nhắn',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_none_rounded),
          label: 'Thông báo',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Thêm',
        ),
      ],
    ),
  );
}
