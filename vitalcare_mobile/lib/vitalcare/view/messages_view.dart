import 'package:flutter/material.dart';
import '../api/api.dart';
import 'chat_screen.dart';
import 'common.dart';

/// The account's conversations with clinics (`/my_conversations`).
///
/// For a caregiver ([caregiver]), a new message is about one of the patients
/// who share with them, to a clinic that looks after that patient.
class MessagesView extends StatefulWidget {
  const MessagesView({super.key, this.caregiver = false});

  final bool caregiver;

  @override
  State<MessagesView> createState() => _MessagesViewState();
}

class _MessagesViewState extends State<MessagesView> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);
  final _search = TextEditingController();
  List<Conversation> _conversations = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await Api.instance.chat.list();
      if (mounted) setState(() => _conversations = list);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _initials(String name) {
    final words = name
        .replaceAll(RegExp(r'^(Phòng khám|PK)\s+', caseSensitive: false), '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'PK';
    return (words.first[0] + (words.length > 1 ? words.last[0] : ''))
        .toUpperCase();
  }

  String _title(Conversation c) => c.aboutName == null
      ? (c.clinicName ?? 'Phòng khám')
      : '${c.clinicName ?? 'Phòng khám'} · về ${c.aboutName}';

  Future<void> _openChat(ChatScreen screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _load();
  }

  void _open(Conversation conversation) => _openChat(
    ChatScreen(
      clinicId: conversation.clinicId ?? '',
      clinicName: conversation.clinicName ?? 'Phòng khám',
      conversationId: conversation.id,
      aboutCustomerId: conversation.aboutCustomerId,
      aboutName: conversation.aboutName,
    ),
  );

  /// Picks one item in a bottom sheet; null when dismissed.
  Future<T?> _pick<T>(
    String title,
    Future<List<T>> items,
    Widget Function(BuildContext, T) tile,
    String empty,
  ) => showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            FutureBuilder<List<T>>(
              future: items,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingBlock();
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      errorText(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final list = snapshot.data!;
                if (list.isEmpty) return EmptyBlock(message: empty);
                return Column(
                  children: [for (final item in list) tile(context, item)],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );

  Widget _clinicTile(BuildContext context, Clinic clinic) => ListTile(
    leading: CircleAvatar(
      backgroundColor: const Color(0xFFDFF3EF),
      foregroundColor: _primary,
      child: Text(_initials(clinic.name)),
    ),
    title: Text(clinic.name),
    subtitle: clinic.address == null ? null : Text(clinic.address!),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => Navigator.pop(context, clinic),
  );

  Future<void> _newMessage() async {
    SharedPatient? patient;
    if (widget.caregiver) {
      patient = await _pick<SharedPatient>(
        'Nhắn về người bệnh',
        Api.instance.sharing.sharedWithMe(),
        (context, p) => ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFDFF3EF),
            foregroundColor: _primary,
            child: Text(p.initials),
          ),
          title: Text(p.fullName),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.pop(context, p),
        ),
        'Chưa có ai chia sẻ sức khỏe với bạn.',
      );
      if (!mounted || patient == null) return;
    }
    final about = patient;
    final clinics = about == null
        ? Api.instance.appointments.clinics()
        : Future.wait([
            Api.instance.chat.clinicsAbout(about.customerId),
            Api.instance.appointments.clinics(),
          ]).then((results) {
            final ids = results[0] as List<String>;
            return (results[1] as List<Clinic>)
                .where((c) => ids.contains(c.id))
                .toList();
          });
    final clinic = await _pick<Clinic>(
      'Chọn phòng khám',
      clinics,
      _clinicTile,
      about == null
          ? 'Chưa có phòng khám nào nhận tin nhắn.'
          : 'Chưa có phòng khám nào theo dõi ${about.fullName}.',
    );
    if (!mounted || clinic == null) return;
    // One conversation per clinic (and patient): continue it when it exists.
    final existing = _conversations
        .where(
          (c) =>
              c.clinicId == clinic.id && c.aboutCustomerId == about?.customerId,
        )
        .firstOrNull;
    _openChat(
      ChatScreen(
        clinicId: clinic.id,
        clinicName: clinic.name,
        conversationId: existing?.id,
        aboutCustomerId: about?.customerId,
        aboutName: about?.fullName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible = _conversations
        .where(
          (c) => '${_title(c)} ${c.lastMessagePreview ?? ''}'
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
                          borderSide: const BorderSide(
                            color: Color(0xFFA9C1BE),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFA9C1BE),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loading && _conversations.isEmpty)
                      const LoadingBlock(),
                    if (_error != null)
                      ErrorBlock(error: _error!, onRetry: _load),
                    if (!_loading && _error == null && visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          _conversations.isEmpty
                              ? 'Chưa có cuộc trò chuyện nào. Bấm "Tin nhắn mới" để nhắn cho phòng khám.'
                              : 'Không tìm thấy cuộc trò chuyện',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _muted, fontSize: 15),
                        ),
                      ),
                    for (final conversation in visible)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Material(
                          color: Colors.white,
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFFBDD3CE)),
                          ),
                          child: InkWell(
                            onTap: () => _open(conversation),
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
                                      _initials(conversation.clinicName ?? ''),
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
                                          _title(conversation),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          conversation.lastMessagePreview ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: _muted,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          conversation.lastMessageAt == null
                                              ? ''
                                              : ago(
                                                  conversation.lastMessageAt!,
                                                ),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (conversation.unread > 0) ...[
                                    const SizedBox(width: 8),
                                    Semantics(
                                      label: '${conversation.unread} tin mới',
                                      child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: const BoxDecoration(
                                          color: _primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          conversation.unread > 9
                                              ? '9+'
                                              : '${conversation.unread}',
                                          style: const TextStyle(
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
      ),
    );
  }
}
