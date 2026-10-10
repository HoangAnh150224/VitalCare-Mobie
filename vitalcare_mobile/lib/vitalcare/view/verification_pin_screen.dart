import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VerificationPinScreen extends StatefulWidget {
  const VerificationPinScreen({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<VerificationPinScreen> createState() => _VerificationPinScreenState();
}

class _VerificationPinScreenState extends State<VerificationPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinKey = GlobalKey<FormFieldState<String>>();
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF007C80);

  @override
  void dispose() {
    for (final controller in _digits) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updatePin(int index, String value) {
    if (value.length > 1) {
      // A complete pasted or autofilled code always starts at the first box.
      final start = value.length == 6 ? 0 : index;
      for (var i = start; i < 6; i++) {
        final offset = i - start;
        _digits[i].text = offset < value.length ? value[offset] : '';
      }
      final next = (start + value.length).clamp(0, 5);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _pinKey.currentState?.didChange(_digits.map((c) => c.text).join());
  }

  Widget _buildPinInput() {
    return FormField<String>(
      key: _pinKey,
      validator: (_) => _digits.every((c) => RegExp(r'^\d$').hasMatch(c.text))
          ? null
          : 'Vui lòng nhập đủ 6 chữ số',
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(6, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index < 5 ? 8 : 0),
                  child: TextField(
                    controller: _digits[index],
                    focusNode: _focusNodes[index],
                    onTap: () {
                      _digits[index].selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _digits[index].text.length,
                      );
                    },
                    onChanged: (value) => _updatePin(index, value),
                    onSubmitted: (_) => index == 5
                        ? _verify()
                        : _focusNodes[index + 1].requestFocus(),
                    keyboardType: TextInputType.number,
                    textInputAction: index == 5
                        ? TextInputAction.done
                        : TextInputAction.next,
                    autofillHints: index == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    cursorColor: _link,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                    decoration: InputDecoration(
                      semanticCounterText: 'Chữ số ${index + 1} trên 6',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: field.hasError
                              ? Theme.of(context).colorScheme.error
                              : const Color(0xFFCCDADC),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (field.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                field.errorText!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUnavailable() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Chức năng xác nhận SMS chưa được kết nối máy chủ.'),
        ),
      );
  }

  void _verify() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    _showUnavailable();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF6FBF9),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFDFF3EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDFF3EF),
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại số điện thoại',
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDFF3EF), Color(0xFFEEF9F6), Color(0xFFF6FBF9)],
              stops: [0, 0.55, 1],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: EdgeInsets.zero,
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Container(
                                width: 104,
                                height: 104,
                                clipBehavior: Clip.antiAlias,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFE1EDEA),
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/images/logo.jpg',
                                  height: 80,
                                  width: 88,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'VitalCare',
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Nhập mã PIN',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.25,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Nhập mã xác nhận gồm 6 chữ số từ SMS để khôi phục mật khẩu cho số điện thoại',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFF597677),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.phoneNumber,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: _link,
                              ),
                            ),
                            const SizedBox(height: 28),
                            const Text(
                              'Mã PIN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildPinInput(),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: _verify,
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                elevation: 0,
                                shadowColor: const Color(0x40008C91),
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'Xác nhận',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Bạn chưa nhận được mã?',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF597677)),
                            ),
                            TextButton(
                              onPressed: _showUnavailable,
                              style: TextButton.styleFrom(
                                foregroundColor: _link,
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: const Text(
                                'Gửi lại mã SMS',
                                style: TextStyle(
                                  fontSize: 15,
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
            ),
          ),
        ),
      ),
    );
  }
}
