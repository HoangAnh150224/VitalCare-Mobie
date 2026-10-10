import 'package:flutter/material.dart';

class FirstAidGuideScreen extends StatelessWidget {
  const FirstAidGuideScreen({super.key, required this.title});

  final String title;
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);
  static const _primary = Color(0xFF008C91);

  Widget _section(
    String heading,
    String content,
    IconData icon, {
    bool warning = false,
  }) {
    final color = warning ? const Color(0xFFAC4949) : _primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFF5F2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: warning ? const Color(0xFFF0D9D2) : const Color(0xFFE0ECE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  heading,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: warning ? color : _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.6, color: _muted),
          ),
        ],
      ),
    );
  }

  void _contact(BuildContext context) {
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
              const Text(
                'Liên hệ khẩn cấp',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Chưa cấu hình số liên hệ khẩn cấp. Nút này chưa thực hiện cuộc gọi. Khi cần trợ giúp khẩn cấp, hãy dùng ứng dụng Điện thoại để gọi dịch vụ cấp cứu tại nơi bạn đang ở.',
                style: TextStyle(fontSize: 15, height: 1.6, color: _muted),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6FBF9),
    appBar: AppBar(
      backgroundColor: const Color(0xFFDFF3EF),
      surfaceTintColor: Colors.transparent,
      foregroundColor: _ink,
      centerTitle: true,
      title: const Text(
        'Hướng dẫn sơ cứu',
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
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Hướng dẫn tham khảo, không dùng để chẩn đoán hoặc thay thế chăm sóc y tế.',
                    style: TextStyle(fontSize: 13, height: 1.6, color: _muted),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nội dung mẫu · Chờ chuyên môn duyệt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _section(
                    'Tình huống',
                    '[Mô tả tình huống đã được chuyên môn duyệt.]',
                    Icons.info_outline_rounded,
                  ),
                  _section(
                    'Việc cần làm ngay',
                    '[Các bước theo hướng dẫn y tế đã được duyệt.]',
                    Icons.checklist_rounded,
                  ),
                  _section(
                    'Cảnh báo quan trọng',
                    '[Dấu hiệu cần được hỗ trợ y tế khẩn cấp.]',
                    Icons.warning_amber_rounded,
                    warning: true,
                  ),
                  _section(
                    'Những điều không nên làm',
                    '[Các hành động cần tránh.]',
                    Icons.block_outlined,
                  ),
                  _section(
                    'Khi nào cần hỗ trợ y tế',
                    '[Hướng dẫn rõ khi nào và cách tìm trợ giúp.]',
                    Icons.medical_services_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: FilledButton.icon(
              onPressed: () => _contact(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFAC4949),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.phone_in_talk_outlined, size: 21),
              label: const Text(
                'Liên hệ khẩn cấp',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
