import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';

/// One published article (`/public/first_aid/{id}`): its summary, the body's
/// sections, the emergency warning and, when there is one, its video.
class FirstAidGuideScreen extends StatefulWidget {
  const FirstAidGuideScreen({
    super.key,
    required this.articleId,
    required this.title,
  });

  final int articleId;
  final String title;

  @override
  State<FirstAidGuideScreen> createState() => _FirstAidGuideScreenState();
}

class _FirstAidGuideScreenState extends State<FirstAidGuideScreen> {
  static const _ink = Color(0xFF164E50);
  static const _muted = Color(0xFF657E80);
  static const _primary = Color(0xFF008C91);

  FirstAidArticle? _article;
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
      final article = await Api.instance.firstAid.get(widget.articleId);
      if (mounted) setState(() => _article = article);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> _content() {
    if (_loading) return const [LoadingBlock()];
    if (_error != null) return [ErrorBlock(error: _error!, onRetry: _load)];
    final article = _article!;
    final video = Uri.tryParse(article.videoUrl ?? '');
    return [
      if (article.summary != null && article.summary!.isNotEmpty)
        _section('Tình huống', article.summary!, Icons.info_outline_rounded),
      if (video != null && video.hasScheme)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: OutlinedButton.icon(
            onPressed: () => openExternal(context, video),
            style: OutlinedButton.styleFrom(
              foregroundColor: _primary,
              backgroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: Color(0xFFCCDADC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Xem video'),
          ),
        ),
      for (final (heading, text) in article.sections)
        _section(heading ?? 'Việc cần làm', text, Icons.checklist_rounded),
      if (article.emergencyWarning != null &&
          article.emergencyWarning!.isNotEmpty)
        _section(
          'Cảnh báo quan trọng',
          article.emergencyWarning!,
          Icons.warning_amber_rounded,
          warning: true,
        ),
    ];
  }

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
    const message =
        'VitalCare không phải dịch vụ cấp cứu. Trong tình huống nguy hiểm đến tính mạng, hãy gọi 115 ngay.';
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
                message,
                style: TextStyle(fontSize: 15, height: 1.6, color: _muted),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => callPhone(context, '115'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFAC4949),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.phone_in_talk_outlined),
                label: const Text('Gọi 115 · Cấp cứu y tế'),
              ),
              const SizedBox(height: 8),
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
                    _article?.title ?? widget.title,
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
                  if (_article?.category != null)
                    Text(
                      _article!.category!.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ..._content(),
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
