import 'package:flutter/material.dart';

class SharedHealthScreen extends StatelessWidget {
  const SharedHealthScreen({super.key, required this.personIndex});
  final int personIndex;
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0ECE9)),
    ),
    child: child,
  );

  Widget _metric(
    String label,
    String value,
    IconData icon,
    Color color,
    String time,
  ) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 14),
        Text(label, style: const TextStyle(fontSize: 12, color: _muted)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Bình thường',
          style: TextStyle(fontSize: 11, color: Color(0xFF33846B)),
        ),
        const SizedBox(height: 5),
        Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
      ],
    ),
  );

  Widget _section(String title, String text, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.6, color: _muted),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final alex = personIndex == 0;
    final name = alex ? 'Alex Morgan' : 'Casey Morgan';
    final firstName = alex ? 'Alex' : 'Casey';
    final time = alex ? 'Hôm nay 09:41' : 'Hôm qua 08:15';
    final spo2 = alex ? '98%' : '97%';
    final pulse = alex ? '72 bpm' : '75 bpm';
    final temperature = alex ? '33,4°C' : '33,2°C';
    final now = DateTime.now();
    final appointment = DateTime(now.year, now.month, now.day + (alex ? 2 : 9));
    final expires = DateTime(now.year, now.month, now.day + 14);
    String date(DateTime value) =>
        '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFF3EF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Sức khỏe được chia sẻ',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Dữ liệu chia sẻ mẫu',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2F2ED),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: _primary,
                            size: 21,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Bạn chỉ được xem thông tin mà bệnh nhân chia sẻ với bạn.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          _metric(
                            'SpO₂',
                            spo2,
                            Icons.water_drop_outlined,
                            const Color(0xFF298CAB),
                            time,
                          ),
                          _metric(
                            'Nhịp tim',
                            pulse,
                            Icons.favorite_border_rounded,
                            const Color(0xFFD0767F),
                            time,
                          ),
                          _metric(
                            'Nhiệt độ da',
                            temperature,
                            Icons.thermostat_rounded,
                            const Color(0xFFC28B3A),
                            time,
                          ),
                        ];
                        if (constraints.maxWidth < 320 ||
                            MediaQuery.textScalerOf(context).scale(14) > 19) {
                          return Column(
                            children: [
                              for (final card in cards)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
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
                    const SizedBox(height: 18),
                    _section(
                      'Lần đo gần nhất · $time',
                      'SpO₂ $spo2 · Nhịp tim $pulse · Da $temperature',
                      Icons.history_rounded,
                    ),
                    _section(
                      'Thông báo quan trọng',
                      '$firstName đã chia sẻ cập nhật sức khỏe mới.',
                      Icons.notifications_none_rounded,
                    ),
                    _section(
                      'Lịch hẹn sắp tới',
                      '${date(appointment)} · ${alex ? '10:30' : '09:00'} · Phòng khám Trung Tâm',
                      Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$firstName chia sẻ · Đến ${date(expires)}/${expires.year}',
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
