import 'package:flutter/material.dart';

class HealthSharingScreen extends StatefulWidget {
  const HealthSharingScreen({super.key});

  @override
  State<HealthSharingScreen> createState() => _HealthSharingScreenState();
}

class _HealthSharingScreenState extends State<HealthSharingScreen> {
  static const _ink = Color(0xFF164E50);
  static const _primary = Color(0xFF008C91);
  static const _muted = Color(0xFF657E80);
  static const _options = [
    'Chỉ số sức khỏe và các lần đo gần đây',
    'Thông báo sức khỏe quan trọng',
    'Lịch hẹn',
  ];
  final Set<int> _selected = {0};
  String _recipient = 'Sam Morgan';
  late DateTime _until = DateTime.now().add(const Duration(days: 14));
  String get _date =>
      '${_until.day.toString().padLeft(2, '0')}/${_until.month.toString().padLeft(2, '0')}/${_until.year}';
  String get _summary => _selected.isEmpty
      ? 'Chọn ít nhất một loại thông tin để chia sẻ.'
      : 'Bạn chia sẻ ${(_selected.toList()..sort()).map((i) => _options[i].toLowerCase()).join(', ')} với $_recipient đến ngày $_date.';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _until.isBefore(today) ? today : _until,
      firstDate: today,
      lastDate: DateTime(today.year + 5, today.month, today.day),
      helpText: 'Chia sẻ đến ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (date != null && mounted) setState(() => _until = date);
  }

  void _confirm() {
    if (_selected.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận chia sẻ mẫu'),
        content: SingleChildScrollView(
          child: Text(
            '$_summary\n\nChưa có dữ liệu nào được chia sẻ. Tính năng này cần kết nối tài khoản người nhận và máy chủ.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
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
        'Chia sẻ sức khỏe',
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
                    'Bạn muốn chia sẻ với ai?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _recipient,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: _primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCCDADC)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Sam Morgan',
                        child: Text('Sam Morgan'),
                      ),
                      DropdownMenuItem(
                        value: 'Alex Morgan',
                        child: Text('Alex Morgan'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _recipient = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Danh sách người nhận mẫu',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chọn thông tin muốn chia sẻ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE0ECE9)),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < _options.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Color(0xFFE0ECE9),
                            ),
                          CheckboxListTile(
                            value: _selected.contains(i),
                            onChanged: (value) => setState(() {
                              if (value == true) {
                                _selected.add(i);
                              } else {
                                _selected.remove(i);
                              }
                            }),
                            activeColor: _primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            title: Text(
                              _options[i],
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chia sẻ đến ngày',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _pickDate,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _ink,
                      padding: const EdgeInsets.all(16),
                      side: const BorderSide(color: Color(0xFFCCDADC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: _primary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _date,
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        const Icon(Icons.expand_more_rounded, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F2ED),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _summary,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: _ink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: const Text(
                      'Xác nhận chia sẻ',
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
