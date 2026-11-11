import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

/// The patients who share their health with the caregiver (`/shared_patients`).
class SharedPeopleView extends StatefulWidget {
  const SharedPeopleView({super.key, required this.onPersonSelected});

  final ValueChanged<SharedPatient> onPersonSelected;

  @override
  State<SharedPeopleView> createState() => _SharedPeopleViewState();
}

class _SharedPeopleViewState extends State<SharedPeopleView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);

  List<SharedPatient> _people = const [];
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
      final people = await Api.instance.sharing.sharedWithMe();
      if (mounted) setState(() => _people = people);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _shares(SharedPatient person) => [
    if (person.shareVitals) 'chỉ số',
    if (person.shareAlerts) 'cảnh báo',
    if (person.shareAppointments) 'lịch hẹn',
  ].join(', ');

  Widget _person(SharedPatient person) {
    final name = person.fullName;
    final initials = person.initials;
    final relation = 'Chia sẻ ${_shares(person)}';
    final latest = person.expiresAt == null
        ? 'Không giới hạn thời gian'
        : 'Đến ${fullDate(person.expiresAt!)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFBDD3CE)),
        ),
        child: InkWell(
          onTap: () => widget.onPersonSelected(person),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE4F4EF),
                  foregroundColor: _primary,
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$relation · Đang chia sẻ',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        latest,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: _muted,
                ),
              ],
            ),
          ),
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
                  const Text(
                    'Thông tin sức khỏe được chia sẻ với bạn.',
                    style: TextStyle(fontSize: 15, height: 1.5, color: _ink),
                  ),
                  const SizedBox(height: 18),
                  if (_loading) const LoadingBlock(),
                  if (!_loading && _error != null)
                    ErrorBlock(error: _error!, onRetry: _load),
                  if (!_loading && _error == null && _people.isEmpty)
                    const EmptyBlock(
                      icon: Icons.people_outline_rounded,
                      message: 'Chưa có ai chia sẻ sức khỏe với bạn.',
                    ),
                  if (!_loading)
                    for (final person in _people) _person(person),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
