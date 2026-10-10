import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.showNavigation = true});
  final bool showNavigation;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  bool _unreadOnly = false;
  final Set<int> _unread = {0, 1, 3};
  static const _items = [
    (
      title: 'Cập nhật sức khỏe',
      subtitle: 'Xem kết quả đo gần đây · 10 phút trước',
      icon: Icons.favorite_border_rounded,
      detail: 'Bạn có kết quả đo mẫu mới. Xem các chỉ số trong mục Sức khỏe.',
    ),
    (
      title: 'Nhắc lịch hẹn',
      subtitle: 'BS. Taylor · 25/09, 10:30',
      icon: Icons.calendar_month_outlined,
      detail:
          'Lịch hẹn mẫu với BS. Taylor tại Phòng khám Trung Tâm. Vui lòng đến sớm 10 phút.',
    ),
    (
      title: 'Thiết bị mất kết nối',
      subtitle: 'Vui lòng kết nối lại thiết bị VitalCare.',
      icon: Icons.bluetooth_disabled_rounded,
      detail:
          'Thông báo mẫu: thiết bị đã mất kết nối. Chức năng kết nối thiết bị thực tế chưa được tích hợp.',
    ),
    (
      title: 'Tin nhắn mới · Jamie Lee',
      subtitle: 'Nhân viên y tế gửi tin nhắn · 09:30',
      icon: Icons.chat_bubble_outline_rounded,
      detail:
          'Thông báo tin nhắn mẫu từ Jamie Lee. Chưa có nội dung tin nhắn thực tế.',
    ),
  ];

  void _open(int index) {
    setState(() => _unread.remove(index));
    final item = _items[index];
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
                item.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.detail,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
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

  @override
  Widget build(BuildContext context) {
    final visible = List.generate(
      _items.length,
      (i) => i,
    ).where((i) => !_unreadOnly || _unread.contains(i)).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFF3EF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Thông báo',
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
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Tất cả')),
                        ButtonSegment(value: true, label: Text('Chưa đọc')),
                      ],
                      selected: {_unreadOnly},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => _unreadOnly = selection.single),
                      style: ButtonStyle(
                        minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected)
                              ? _primary
                              : Colors.white,
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith(
                          (s) => s.contains(WidgetState.selected)
                              ? Colors.white
                              : _ink,
                        ),
                        side: const WidgetStatePropertyAll(
                          BorderSide(color: Color(0xFFCCDADC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _unread.isEmpty
                          ? null
                          : () => setState(_unread.clear),
                      style: TextButton.styleFrom(
                        foregroundColor: _primary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Đánh dấu tất cả đã đọc'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Dữ liệu mẫu',
                      style: TextStyle(fontSize: 12, color: _muted),
                    ),
                    const SizedBox(height: 12),
                    if (visible.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 44,
                              color: _primary,
                            ),
                            SizedBox(height: 14),
                            Text(
                              'Bạn đã đọc tất cả thông báo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final index in visible) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: _unread.contains(index)
                                  ? const Color(0xFFB8DDD5)
                                  : const Color(0xFFE0ECE9),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => _open(index),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF8F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _items[index].icon,
                                      color: _primary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _items[index].title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: _unread.contains(index)
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          _items[index].subtitle,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Semantics(
                                    label: _unread.contains(index)
                                        ? 'Chưa đọc'
                                        : 'Đã đọc',
                                    child: Icon(
                                      _unread.contains(index)
                                          ? Icons.circle
                                          : Icons.circle_outlined,
                                      size: 9,
                                      color: _unread.contains(index)
                                          ? _primary
                                          : _muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (index == 2)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2F2ED),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Thông báo mẫu: một số dữ liệu chưa được tải lên. Tính năng đồng bộ tự động chưa được kết nối.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.6,
                              color: _muted,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: !widget.showNavigation
          ? null
          : NavigationBar(
              selectedIndex: 0,
              backgroundColor: Colors.white,
              indicatorColor: Colors.transparent,
              onDestinationSelected: (index) => Navigator.pop(context, index),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
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
    );
  }
}
