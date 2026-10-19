import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'measurement_screen.dart';
import 'measurement_history_screen.dart';
import 'health_view.dart';
import 'appointments_view.dart';
import 'notifications_screen.dart';
import 'messages_view.dart';
import 'profile_view.dart';
import 'first_aid_screen.dart';
import 'exam_registration_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool? _registerForRelative;
  final List<ExamRegistration> _registrations = [];

  Future<void> _registerSelf() async {
    final registration = await Navigator.of(context).push<ExamRegistration>(
      MaterialPageRoute(builder: (_) => const ExamRegistrationScreen()),
    );
    if (!mounted || registration == null) return;
    setState(() {
      _registrations.add(registration);
      _selectedIndex = 2;
    });
  }

  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);

  void _showRegistrationOptions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5FAF8),
      builder: (context) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Đăng ký khám',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bạn muốn đăng ký khám cho ai?',
                  style: TextStyle(color: _muted, fontSize: 15),
                ),
                const SizedBox(height: 20),
                for (final relative in [false, true])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: _registerForRelative == relative
                          ? const Color(0xFFDFF3EF)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _registerForRelative == relative
                              ? _primary
                              : const Color(0xFFBBDDD6),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        selected: _registerForRelative == relative,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          leading: Icon(
                            relative
                                ? Icons.family_restroom
                                : Icons.person_outline,
                            color: _primary,
                          ),
                          title: Text(
                            relative
                                ? 'Đăng ký cho người thân'
                                : 'Đăng ký cho chính mình',
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            _registerForRelative == relative
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: _primary,
                          ),
                          onTap: () {
                            updateSheet(() => _registerForRelative = relative);
                            if (!relative) {
                              Navigator.pop(context);
                              _registerSelf();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  void _openView(String title, Widget view) {
    _open(
      Scaffold(
        appBar: AppBar(title: Text(title)),
        body: view,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0ECE9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: color.withValues(alpha: 0.10),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          Text(unit, style: const TextStyle(color: _muted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _action(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
  }) {
    return Material(
      color: filled ? _primary : Colors.white,
      shape: StadiumBorder(
        side: BorderSide(color: filled ? _primary : const Color(0xFFBBDDD6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
          child: Row(
            children: [
              Icon(icon, size: 25, color: filled ? Colors.white : _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: filled ? Colors.white : _primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _home() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Chỉ số sức khỏe',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    Text(
                      'Dữ liệu mẫu',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _metric(
                        'SpO₂',
                        '98',
                        '%',
                        Icons.water_drop_outlined,
                        const Color(0xFF008C91),
                      ),
                      _metric(
                        'Nhịp tim',
                        '72',
                        'bpm',
                        Icons.favorite_outline,
                        const Color(0xFFE56B7A),
                      ),
                      _metric(
                        'Nhiệt độ da',
                        '33,4',
                        '°C',
                        Icons.thermostat_outlined,
                        const Color(0xFFE4A03B),
                      ),
                    ];
                    final stacked =
                        constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final card in cards)
                          SizedBox(
                            width: stacked
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 20) / 3,
                            child: card,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 26),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final actions = [
                      _action(
                        'Đo sức khỏe',
                        Icons.monitor_heart_outlined,
                        () => _open(const MeasurementScreen()),
                        filled: true,
                      ),
                      _action(
                        'Đăng ký khám',
                        Icons.calendar_month_outlined,
                        _showRegistrationOptions,
                        filled: true,
                      ),
                      _action(
                        'Hồ sơ sức khỏe',
                        Icons.assignment_outlined,
                        () => _openView('Sức khỏe', const HealthView()),
                      ),
                      _action(
                        'Lịch sử đo',
                        Icons.history_rounded,
                        () => _open(const MeasurementHistoryScreen()),
                      ),
                      _action(
                        'Tin nhắn',
                        Icons.chat_bubble_outline_rounded,
                        () => _openView('Tin nhắn', const MessagesView()),
                      ),
                      _action(
                        'Hướng dẫn sơ cứu',
                        Icons.medical_services_outlined,
                        () => _open(const FirstAidScreen()),
                      ),
                    ];
                    final singleColumn =
                        constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(14) > 19;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final action in actions)
                          SizedBox(
                            width: singleColumn
                                ? constraints.maxWidth
                                : (constraints.maxWidth - 12) / 2,
                            child: action,
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 28),
                const Text(
                  'Chăm sóc sức khỏe',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 14),
                _careCard(
                  Icons.insights_rounded,
                  'Theo dõi sức khỏe',
                  'Xem tổng quan và diễn biến các chỉ số của bạn.',
                  () => _openView('Sức khỏe', const HealthView()),
                ),
                const SizedBox(height: 12),
                _careCard(
                  Icons.calendar_month_outlined,
                  'Lịch hẹn của bạn',
                  'Xem lịch khám và thông tin cuộc hẹn.',
                  () => setState(() => _selectedIndex = 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _careCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF8F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: _primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: _muted),
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
                if (!mounted || tab == null || tab < 0 || tab > 4) return;
                setState(() => _selectedIndex = tab);
              },
            ),
          ],
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFDFF3EF),
          surfaceTintColor: Colors.transparent,
          title: Text(
            [
              'Trang chủ',
              'Sức khỏe',
              'Lịch hẹn',
              'Tin nhắn',
              'Cá nhân & cài đặt',
            ][_selectedIndex],
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        body: switch (_selectedIndex) {
          1 => const HealthView(),
          2 => AppointmentsView(registrations: _registrations),
          3 => const MessagesView(),
          4 => const ProfileView(),
          _ => Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFDFF3EF), Color(0xFFF5FAF8)],
                stops: [0, 0.5],
              ),
            ),
            child: _home(),
          ),
        },
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFDFF3EF),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 12,
              color: states.contains(WidgetState.selected) ? _primary : _muted,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
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
