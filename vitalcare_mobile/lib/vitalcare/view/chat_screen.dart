import 'dart:async';

import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

/// One conversation with a clinic (`/my_conversations/{id}`). Without
/// [conversationId] the first message starts it (`POST /my_conversations`).
///
/// New replies are picked up by asking again every few seconds while the
/// screen is open.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.clinicId,
    required this.clinicName,
    this.conversationId,
    this.aboutCustomerId,
    this.aboutName,
  });
  final String clinicId;
  final String clinicName;
  final int? conversationId;

  /// The patient a caregiver writes about.
  final int? aboutCustomerId;
  final String? aboutName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);
  static const _pollEvery = Duration(seconds: 10);
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late int? _conversationId = widget.conversationId;
  List<ChatLine> _messages = const [];
  bool _loading = false;
  bool _sending = false;
  Object? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    if (_conversationId != null) {
      _loading = true;
      _refresh(scroll: true);
      _startPolling();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollEvery, (_) => _refresh());
  }

  Future<void> _refresh({bool scroll = false}) async {
    final id = _conversationId;
    if (id == null) return;
    try {
      final thread = await Api.instance.chat.thread(id);
      if (!mounted) return;
      final grew = thread.messages.length != _messages.length;
      setState(() {
        _messages = thread.messages;
        _error = null;
      });
      if (scroll || grew) _scrollToEnd();
    } catch (e) {
      // A failed poll keeps what is on screen; only the first load shows it.
      if (mounted && _messages.isEmpty) setState(() => _error = e);
    } finally {
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (value.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final chat = Api.instance.chat;
      final id = _conversationId;
      if (id == null) {
        final thread = await chat.start(
          widget.clinicId,
          value,
          aboutCustomerId: widget.aboutCustomerId,
        );
        if (!mounted) return;
        setState(() {
          _conversationId = thread.conversation.id;
          _messages = thread.messages;
        });
        _startPolling();
      } else {
        final line = await chat.send(id, value);
        if (!mounted) return;
        setState(() => _messages = [..._messages, line]);
      }
      _text.clear();
      _scrollToEnd();
    } catch (e) {
      // The text stays in the box so it can be sent again.
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(ChatLine message) {
    final at = message.sentAt;
    final when = at == null ? '' : relativeTime(at);
    if (!message.mine) {
      return message.senderName == null
          ? when
          : '${message.senderName} · $when';
    }
    return '$when · ${message.read ? 'Đã xem' : 'Đã gửi'}';
  }

  Widget _image(ChatLine message) {
    final chat = Api.instance.chat;
    final id = _conversationId;
    final placeholder = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF8F5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Column(
        children: [
          Icon(Icons.image_outlined, size: 32, color: _primary),
          SizedBox(height: 8),
          Text('Ảnh đính kèm', style: TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
    if (id == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        chat.imageUri(id, message.id).toString(),
        headers: chat.imageHeaders,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }

  void _attach() =>
      showNotice(context, 'Chức năng chọn và tải ảnh chưa được tích hợp.');

  /// Little height left for the conversation: a small phone, a phone on its side, or the keyboard
  /// up. The guidance line and the composer's label go, and the composer becomes one row, so the
  /// messages keep the room.
  bool _compact(BuildContext context) =>
      MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom <
      600;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6FBF9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFDFF3EF),
      foregroundColor: _ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: const Text(
        'Trò chuyện bảo mật',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF9F6),
                  border: Border(bottom: BorderSide(color: Color(0xFFBDD3CE))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.aboutName == null
                          ? widget.clinicName
                          : '${widget.clinicName} · về ${widget.aboutName}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (!_compact(context)) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Tin nhắn được gửi tới nhân viên phòng khám. Khi khẩn cấp, hãy gọi 115.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: _muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const LoadingBlock()
                    : _error != null
                    ? ErrorBlock(
                        error: _error!,
                        onRetry: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _refresh(scroll: true);
                        },
                      )
                    : _messages.isEmpty
                    ? const EmptyBlock(
                        icon: Icons.chat_bubble_outline_rounded,
                        message: 'Hãy gửi tin nhắn đầu tiên cho phòng khám.',
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(18),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return Align(
                            alignment: message.mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.9,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: message.mine
                                      ? const Color(0xFFDFF3EF)
                                      : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: Radius.circular(
                                      message.mine ? 16 : 4,
                                    ),
                                    bottomRight: Radius.circular(
                                      message.mine ? 4 : 16,
                                    ),
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFFDDEBE6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: message.mine
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (message.image)
                                      _image(message)
                                    else
                                      SizedBox(
                                        width: double.infinity,
                                        child: Text(
                                          message.text ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.5,
                                            color: _ink,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _time(message),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Container(
                padding: _compact(context)
                    ? const EdgeInsets.fromLTRB(12, 8, 12, 8)
                    : const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFBDD3CE))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_compact(context)) ...[
                      const Text(
                        'Tin nhắn',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TextField(
                      controller: _text,
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: _compact(context) ? 2 : 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        // Compact: attach and send sit inside the field instead of a row of buttons.
                        prefixIcon: _compact(context)
                            ? IconButton(
                                onPressed: _attach,
                                tooltip: 'Đính kèm ảnh',
                                color: _primary,
                                icon: const Icon(Icons.image_outlined),
                              )
                            : null,
                        suffixIcon: _compact(context)
                            ? IconButton(
                                onPressed: _text.text.trim().isEmpty || _sending
                                    ? null
                                    : _send,
                                tooltip: 'Gửi',
                                color: _primary,
                                icon: const Icon(Icons.send_rounded),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
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
                    if (!_compact(context)) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _attach,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primary,
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(
                                  color: Color(0xFFA9C1BE),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.image_outlined, size: 19),
                              label: const Text('Đính kèm ảnh'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _text.text.trim().isEmpty || _sending
                                  ? null
                                  : _send,
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.send_rounded, size: 18),
                              label: Text(_sending ? 'Đang gửi' : 'Gửi'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
