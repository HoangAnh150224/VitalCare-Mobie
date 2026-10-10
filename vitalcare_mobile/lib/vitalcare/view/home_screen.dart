import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_screen.dart';
import 'health_view.dart';
import 'appointments_view.dart';
import 'notifications_screen.dart';
import 'messages_view.dart';
import 'profile_view.dart';

import 'measurement_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _showMore() => setState(() => _selectedIndex = 4);

  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  void _showDetails(BuildContext context, String title, String message) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
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
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 24),
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

  Widget _metric(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bình thường',
            style: TextStyle(fontSize: 11, color: Color(0xFF33846B)),
          ),
          const SizedBox(height: 5),
          const Text(
            'Hôm nay 09:41',
            style: TextStyle(fontSize: 10, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String detail,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE0ECE9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetails(context, title, detail),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF8F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 23),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAF8),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFDFF3EF),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          actions: [
            IconButton(
              tooltip: 'Thông báo',
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: _primary,
              ),
              onPressed: () async {
                final tab = await Navigator.of(context).push<int>(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
                if (!mounted || !context.mounted || tab == null) return;
                if (tab < 4) {
                  setState(() => _selectedIndex = tab);
                } else {
                  _showMore();
                }
              },
            ),
          ],
          title: Text(
            [
              'Trang chủ',
              'Sức khỏe',
              'Lịch hẹn',
              'Tin nhắn',
              'Cá nhân & cài đặt',
            ][_selectedIndex],
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        body: _selectedIndex == 4
            ? const ProfileView()
            : _selectedIndex == 3
            ? const MessagesView()
            : _selectedIndex == 2
            ? const AppointmentsView()
            : _selectedIndex == 1
            ? const HealthView()
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
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chào buổi sáng, Alex',
                                        style: TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Cùng theo dõi sức khỏe hôm nay',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 46,
                                  height: 46,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.wb_sunny_outlined,
                                    color: Color(0xFFC58B35),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tổng quan sức khỏe',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Dữ liệu mẫu',
                                  style: TextStyle(fontSize: 11, color: _muted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final cards = [
                                  _metric(
                                    'SpO₂',
                                    '98',
                                    '%',
                                    Icons.water_drop_outlined,
                                    const Color(0xFF298CAB),
                                  ),
                                  _metric(
                                    'Nhịp tim',
                                    '72',
                                    ' bpm',
                                    Icons.favorite_border_rounded,
                                    const Color(0xFFD0767F),
                                  ),
                                  _metric(
                                    'Nhiệt độ da',
                                    '33,4',
                                    '°C',
                                    Icons.thermostat_rounded,
                                    const Color(0xFFC28B3A),
                                  ),
                                ];
                                if (constraints.maxWidth < 300 ||
                                    MediaQuery.textScalerOf(context).scale(14) >
                                        19) {
                                  return Column(
                                    children: [
                                      for (final card in cards)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: card,
                                          ),
                                        ),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < cards.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 10),
                                      Expanded(child: cards[i]),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: Color(0xFF33846B),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Các chỉ số gần đây đang ổn định.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const MeasurementScreen(),
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.monitor_heart_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('Đo ngay'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const MeasurementHistoryScreen(),
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _primary,
                                      backgroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 14,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFBBDDD6),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Text(
                                      'Xem lịch sử đo',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _infoCard(
                              context: context,
                              icon: Icons.watch_outlined,
                              title: 'Đã kết nối thiết bị',
                              subtitle: 'Pin 82% · Thiết bị mẫu',
                              detail:
                                  'Đây là trạng thái thiết bị mẫu. Chức năng kết nối và đọc mức pin thực tế chưa được tích hợp.',
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Dành cho bạn',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _infoCard(
                              context: context,
                              icon: Icons.calendar_month_outlined,
                              title: 'Lịch hẹn sắp tới · 25/09',
                              subtitle:
                                  'BS. Taylor · 10:30\nPhòng khám Trung Tâm',
                              detail:
                                  'Lịch hẹn mẫu\nNgày 25/09 · 10:30\nBS. Taylor\nPhòng khám Trung Tâm',
                            ),
                            const SizedBox(height: 12),
                            _infoCard(
                              context: context,
                              icon: Icons.chat_bubble_outline_rounded,
                              title: 'Cập nhật quan trọng',
                              subtitle:
                                  'Bạn có tin nhắn mới từ nhân viên y tế.',
                              detail:
                                  'Thông báo mẫu. Chưa có nội dung tin nhắn thực tế từ nhân viên y tế.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFDFF3EF),
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected) ? _primary : _muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          onDestinationSelected: (index) {
            if (index < 4) {
              setState(() => _selectedIndex = index);
              return;
            }
            _showMore();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: _primary),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              label: 'Sức khỏe',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Lịch hẹn',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              label: 'Tin nhắn',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              label: 'Thêm',
            ),
          ],
        ),
      ),
    );
  }
}
