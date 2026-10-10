import 'package:flutter/material.dart';
import 'chat_screen.dart';

class MessagesView extends StatefulWidget {
  const MessagesView({super.key});

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _contacts = [
    (
      name: 'Jamie Lee',
      role: 'Điều dưỡng',
      initials: 'JL',
      preview: 'Hôm nay bạn thấy thế nào?',
      time: '09:30',
    ),
    (
      name: 'BS. Taylor',
      role: 'Bác sĩ',
      initials: 'TL',
      preview: 'Hẹn gặp bạn vào thứ Sáu',
      time: 'Hôm qua',
    ),
  ];
  final _search = TextEditingController();
  bool _jamieUnread = true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(int index) {
    if (index == 0) setState(() => _jamieUnread = false);
    final contact = _contacts[index];
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          name: contact.name,
          role: contact.role,
          greeting: contact.preview,
        ),
      ),
    );
  }

  Future<void> _newMessage() async {
    final index = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Chọn người nhận',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            for (var i = 0; i < _contacts.length; i++)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFDFF3EF),
                  foregroundColor: _primary,
                  child: Text(_contacts[i].initials),
                ),
                title: Text(_contacts[i].name),
                subtitle: Text(_contacts[i].role),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, i),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
    if (!mounted || index == null) return;
    _open(index);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = List.generate(_contacts.length, (i) => i)
        .where(
          (i) =>
              '${_contacts[i].name} ${_contacts[i].role} ${_contacts[i].preview}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return Container(
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
                    'Tìm kiếm',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Tìm cuộc trò chuyện',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: _primary,
                      ),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Xóa tìm kiếm',
                              onPressed: () => setState(_search.clear),
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCCDADC)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCCDADC)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dữ liệu mẫu',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        'Không tìm thấy cuộc trò chuyện',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _muted, fontSize: 15),
                      ),
                    ),
                  for (final index in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Material(
                        color: Colors.white,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE0ECE9)),
                        ),
                        child: InkWell(
                          onTap: () => _open(index),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 23,
                                  backgroundColor: const Color(0xFFE4F4EF),
                                  foregroundColor: _primary,
                                  child: Text(
                                    _contacts[index].initials,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_contacts[index].name} · ${_contacts[index].role}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        _contacts[index].preview,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: _muted,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        _contacts[index].time,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (index == 0 && _jamieUnread) ...[
                                  const SizedBox(width: 8),
                                  Semantics(
                                    label: '2 tin mới',
                                    child: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: const BoxDecoration(
                                        color: _primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Text(
                                        '2',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _newMessage,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.edit_square, size: 20),
                    label: const Text(
                      'Tin nhắn mới',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
