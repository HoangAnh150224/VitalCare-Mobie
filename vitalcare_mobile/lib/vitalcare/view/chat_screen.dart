import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.name,
    required this.role,
    required this.greeting,
  });
  final String name;
  final String role;
  final String greeting;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  final _text = TextEditingController();
  final _scroll = ScrollController();
  late final List<({String text, String time, bool mine, bool image})>
  _messages = [
    (text: widget.greeting, time: '09:30', mine: false, image: false),
    if (widget.name == 'Jamie Lee') ...[
      (
        text: 'Tôi muốn hỏi về kết quả đo hôm nay.',
        time: '09:31 · Đã đọc (mẫu)',
        mine: true,
        image: false,
      ),
      (
        text: 'Ảnh đính kèm mẫu',
        time: '09:32 · Đã gửi (mẫu)',
        mine: true,
        image: true,
      ),
    ],
  ];

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    final now = DateTime.now();
    setState(() {
      _messages.add((
        text: value,
        time:
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} · Chưa gửi',
        mine: true,
        image: false,
      ));
      _text.clear();
    });
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

  void _attach() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chức năng chọn và tải ảnh chưa được tích hợp.'),
        ),
      );
  }

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
                  border: Border(bottom: BorderSide(color: Color(0xFFE0ECE9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.name} · ${widget.role}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Bản mô phỏng · Tin nhắn chỉ hiển thị trong phiên này, chưa gửi đến nhân viên y tế.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
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
                            border: Border.all(color: const Color(0xFFDDEBE6)),
                          ),
                          child: Column(
                            crossAxisAlignment: message.mine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (message.image)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 22,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF8F5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Column(
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 32,
                                        color: _primary,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Ảnh đính kèm mẫu',
                                        style: TextStyle(
                                          color: _muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    message.text,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                message.time,
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
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE0ECE9))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Tin nhắn',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _text,
                      onChanged: (_) => setState(() {}),
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFCCDADC),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _attach,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: Color(0xFFCCDADC)),
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
                            onPressed: _text.text.trim().isEmpty ? null : _send,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Gửi'),
                          ),
                        ),
                      ],
                    ),
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
