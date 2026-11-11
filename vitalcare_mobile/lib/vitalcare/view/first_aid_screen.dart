import 'package:flutter/material.dart';
import '../api/api.dart';
import 'common.dart';
import 'first_aid_guide_screen.dart';

/// Published first-aid guidance (`/public/first_aid`), by category.

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF00777C);
  static const _muted = Color(0xFF3E5658);
  final _search = TextEditingController();
  FirstAidCategory? _category;
  static const _categories = [
    FirstAidCategory.respiratory,
    FirstAidCategory.fainting,
    FirstAidCategory.fever,
    FirstAidCategory.wound,
    FirstAidCategory.general,
  ];
  List<FirstAidArticle> _guides = const [];
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final category = _category;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final guides = await Api.instance.firstAid.list(category: category);
      if (mounted && category == _category) setState(() => _guides = guides);
    } catch (e) {
      if (mounted && category == _category) setState(() => _error = e);
    } finally {
      if (mounted && category == _category) setState(() => _loading = false);
    }
  }

  static IconData _icon(FirstAidCategory? category) => switch (category) {
    FirstAidCategory.respiratory => Icons.air_rounded,
    FirstAidCategory.fainting => Icons.personal_injury_outlined,
    FirstAidCategory.fever => Icons.thermostat_rounded,
    FirstAidCategory.wound => Icons.healing_rounded,
    FirstAidCategory.injury => Icons.personal_injury_outlined,
    FirstAidCategory.environment => Icons.wb_sunny_outlined,
    _ => Icons.medical_services_outlined,
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// VitalCare points the way to help; it does not send it.
  void _emergency() => _showInfo(
    'Liên hệ khẩn cấp',
    'VitalCare không phải dịch vụ cấp cứu. Trong tình huống nguy hiểm đến tính mạng, hãy gọi 115 ngay.',
  );

  void _showInfo(String title, String message) {
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
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: _muted,
                ),
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

  Widget _categoryButton(FirstAidCategory category) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () {
          setState(() => _category = _category == category ? null : category);
          _load();
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: _category == category ? _primary : Colors.white,
          foregroundColor: _category == category ? Colors.white : _ink,
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          side: const BorderSide(color: Color(0xFFA9C1BE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          category.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final guides = _guides
        .where(
          (g) => '${g.title} ${g.summary ?? ''} ${g.category?.label ?? ''}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDFF3EF),
        surfaceTintColor: Colors.transparent,
        foregroundColor: _ink,
        centerTitle: true,
        title: const Text(
          'Sơ cứu',
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
                        hintText: 'Tìm hướng dẫn sơ cứu',
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
                    Row(
                      children: _categories
                          .take(3)
                          .map(_categoryButton)
                          .toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _categories
                          .skip(3)
                          .map(_categoryButton)
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _emergency,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_loading) const LoadingBlock(),
                    if (!_loading && _error != null)
                      ErrorBlock(error: _error!, onRetry: _load),
                    if (!_loading && _error == null && guides.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Chưa có hướng dẫn phù hợp.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _muted),
                        ),
                      ),
                    if (!_loading)
                      for (final guide in guides)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: Color(0xFFBDD3CE)),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FirstAidGuideScreen(
                                    articleId: guide.id,
                                    title: guide.title,
                                  ),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF8F5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _icon(guide.category),
                                        color: _primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            guide.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: _ink,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            guide.summary ??
                                                guide.category?.label ??
                                                '',
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
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                      color: _muted,
                                    ),
                                  ],
                                ),
                              ),
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
