import 'package:flutter/material.dart';

class SharedPeopleView extends StatelessWidget {
  const SharedPeopleView({super.key, required this.onPersonSelected});

  final ValueChanged<int> onPersonSelected;
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  Widget _person(
    int index,
    String name,
    String initials,
    String relation,
    String latest,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE0ECE9)),
        ),
        child: InkWell(
          onTap: () => onPersonSelected(index),
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
      child: SingleChildScrollView(
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
                const SizedBox(height: 6),
                const Text(
                  'Dữ liệu mẫu',
                  style: TextStyle(fontSize: 12, color: _muted),
                ),
                const SizedBox(height: 18),
                _person(
                  0,
                  'Alex Morgan',
                  'AM',
                  'Cha/mẹ',
                  'Lần đo hôm nay, 09:41',
                ),
                _person(
                  1,
                  'Casey Morgan',
                  'CM',
                  'Người thân',
                  'Lần đo gần nhất: Hôm qua',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
