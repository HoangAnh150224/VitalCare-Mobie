import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

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
  List<AppNotification> _items = const [];
  bool _loading = true;
  Object? _error;
  bool _markingAll = false;

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
      final items = await Api.instance.notifications.list();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// By the server's notification type (`alert`, `emergency`, `appointment`,
  /// `payment`, `result`, `device`, `chat`).
  IconData _icon(AppNotification item) => switch (item.type) {
    'alert' || 'emergency' => Icons.favorite_border_rounded,
    'appointment' || 'payment' || 'result' => Icons.calendar_month_outlined,
    'device' => Icons.bluetooth_disabled_rounded,
    'chat' => Icons.chat_bubble_outline_rounded,
    _ => Icons.notifications_none_rounded,
  };

  void _replace(AppNotification item) {
    setState(
      () => _items = [
        for (final existing in _items) existing.id == item.id ? item : existing,
      ],
    );
  }

  Future<void> _open(AppNotification item) async {
    if (!item.read) {
      // Shown as read at once; put back if the server refuses.
      _replace(item.markedRead());
      Api.instance.notifications
          .markRead(item.id)
          .then((updated) {
            if (mounted) _replace(updated);
          })
          .catchError((Object e) {
            if (mounted) {
              _replace(item);
              showError(context, e);
            }
          });
    }
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
              if (item.createdAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  relativeTime(item.createdAt!),
                  style: const TextStyle(fontSize: 13, color: _muted),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                item.body ?? '',
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

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await Api.instance.notifications.markAllRead();
      if (mounted) {
        setState(() => _items = [for (final item in _items) item.markedRead()]);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((item) => !_unreadOnly || !item.read).toList();
    final anyUnread = _items.any((item) => !item.read);
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
                          minimumSize: const WidgetStatePropertyAll(
                            Size(0, 48),
                          ),
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
                        onPressed: !anyUnread || _markingAll
                            ? null
                            : _markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: _primary,
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: const Text('Đánh dấu tất cả đã đọc'),
                      ),
                      const SizedBox(height: 12),
                      if (_loading && _items.isEmpty) const LoadingBlock(),
                      if (_error != null)
                        ErrorBlock(error: _error!, onRetry: _load),
                      if (!_loading && _error == null && visible.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 20,
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                size: 44,
                                color: _primary,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _items.isEmpty
                                    ? 'Bạn chưa có thông báo nào'
                                    : 'Bạn đã đọc tất cả thông báo',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final item in visible) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: !item.read
                                    ? const Color(0xFFB8DDD5)
                                    : const Color(0xFFE0ECE9),
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _open(item),
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
                                        _icon(item),
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
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: !item.read
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: _ink,
                                            ),
                                          ),
                                          const SizedBox(height: 7),
                                          Text(
                                            [
                                              if ((item.body ?? '').isNotEmpty)
                                                item.body!,
                                              if (item.createdAt != null)
                                                ago(item.createdAt!),
                                            ].join(' · '),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
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
                                      label: !item.read ? 'Chưa đọc' : 'Đã đọc',
                                      child: Icon(
                                        !item.read
                                            ? Icons.circle
                                            : Icons.circle_outlined,
                                        size: 9,
                                        color: !item.read ? _primary : _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
