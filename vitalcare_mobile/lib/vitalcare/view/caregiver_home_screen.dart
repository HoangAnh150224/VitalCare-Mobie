import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';
import 'messages_view.dart';
import 'notifications_screen.dart';
import 'shared_people_view.dart';
import 'shared_health_screen.dart';

/// The caregiver's side: who shares with them (`/shared_patients`) and the
/// emergency notices they were sent (`/emergency_alerts`).
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
  SharedPatient? _person;
  List<SharedPatient> _people = const [];
  List<EmergencyNotice> _notices = const [];
  bool _loading = true;
  Object? _error;
  int? _acknowledging;

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
      final sharing = Api.instance.sharing;
      final people = await sharing.sharedWithMe();
      // Notices are extra; without them the patients still show.
      final notices = await sharing.emergencies().catchError(
        (Object _) => const <EmergencyNotice>[],
      );
      if (!mounted) return;
      setState(() {
        _people = people;
        _notices = notices;
        if (_person == null ||
            !people.any((p) => p.customerId == _person!.customerId)) {
          _person = people.firstOrNull;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _health(SharedPatient person) {
    setState(() => _person = person);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedHealthScreen(patient: person),
      ),
    );
  }

  Future<void> _notice(EmergencyNotice notice) async {
    final acknowledged = notice.acknowledgedAt != null;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cảnh báo · ${notice.patientName ?? ''}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notice.message ?? 'Chỉ số sức khỏe bất thường.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 20),
              if (!acknowledged)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheet);
                    _acknowledge(notice);
                  },
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                  child: const Text('Đã nhận thông báo'),
                ),
              if (notice.emergencyPhone != null)
                TextButton.icon(
                  onPressed: () => callPhone(context, notice.emergencyPhone!),
                  icon: const Icon(Icons.phone_in_talk_outlined),
                  label: Text('Gọi ${notice.emergencyPhone}'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(sheet),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acknowledge(EmergencyNotice notice) async {
    setState(() => _acknowledging = notice.id);
    try {
      final updated = await Api.instance.sharing.acknowledge(notice.id);
      if (!mounted) return;
      setState(
        () => _notices = [
          for (final n in _notices) n.id == updated.id ? updated : n,
        ],
      );
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _acknowledging = null);
    }
  }

  String _sharing(SharedPatient person) => [
    if (person.shareVitals) 'chỉ số',
    if (person.shareAlerts) 'cảnh báo',
    if (person.shareAppointments) 'lịch hẹn',
  ].join(', ');

  List<Widget> _homeContent() {
    if (_loading) return const [LoadingBlock()];
    if (_error != null) return [ErrorBlock(error: _error!, onRetry: _load)];
    return [
      if (_people.isEmpty)
        const EmptyBlock(
          icon: Icons.people_outline_rounded,
          message: 'Chưa có ai chia sẻ sức khỏe với bạn.',
        ),
      for (final person in _people)
        _card(
          person.fullName,
          'Chia sẻ ${_sharing(person)} · Xem sức khỏe',
          Icons.person_outline_rounded,
          () => _health(person),
        ),
      if (_tab == 0) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: _person == null ? null : () => _health(_person!),
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
                  side: const BorderSide(color: Color(0xFFCCDADC)),
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
        for (final notice in _notices.take(5))
          _card(
            'Cập nhật quan trọng · ${notice.patientName ?? ''}',
            [
              notice.message ?? 'Chỉ số sức khỏe bất thường',
              if (notice.notifiedAt != null) ago(notice.notifiedAt!),
              _acknowledging == notice.id
                  ? 'Đang xác nhận...'
                  : notice.acknowledgedAt == null
                  ? 'Chưa xác nhận'
                  : 'Đã nhận',
            ].join(' · '),
            Icons.favorite_border_rounded,
            () => _notice(notice),
          ),
      ],
    ];
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
        ? const MessagesView(caregiver: true)
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
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_tab == 4) ...[
                            Text(
                              Api.instance.auth.session?.fullName ??
                                  'Tài khoản',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              Api.instance.auth.session?.phone ?? 'Người thân',
                              style: const TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 20),
                            _card(
                              'Về giao diện bệnh nhân',
                              'Quay về giao diện của bạn',
                              Icons.swap_horiz_rounded,
                              () => Navigator.pop(context),
                            ),
                          ] else ...[
                            Text(
                              _tab == 0
                                  ? 'Xin chào${Api.instance.auth.session?.fullName == null ? '' : ', ${Api.instance.auth.session!.fullName!.trim().split(RegExp(r'\s+')).last}'}'
                                  : 'Sức khỏe được chia sẻ',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _loading
                                  ? 'Đang tải...'
                                  : '${_people.length} người đang chia sẻ sức khỏe với bạn.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: _muted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ..._homeContent(),
                          ],
                        ],
                      ),
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
