import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import 'common.dart';
import 'forgot_password_screen.dart';
import 'verification_pin_screen.dart';

/// UC-04 step 1: the number and the account's details; a code is texted next
/// and checked on [VerificationPinScreen], which also offers the profiles the
/// clinic already has with the number.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF007C80);

  /// What the API says when the number already has an account (UC-04 D2).
  static const _phoneTaken = 'Số điện thoại đã được sử dụng';

  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _phoneTakenError = false;
  Map<String, String> _serverErrors = const {};

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_busy) return;
    setState(() {
      _serverErrors = const {};
      _phoneTakenError = false;
    });
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final phone = _phone.text.replaceAll(RegExp(r'[\s().-]'), '');
    setState(() => _busy = true);
    try {
      await Api.instance.auth.requestRegistrationCode(phone);
      if (!mounted) return;
      setState(() => _busy = false);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => VerificationPinScreen(
            phoneNumber: phone,
            registration: (
              fullName: _name.text.trim(),
              password: _password.text,
            ),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverErrors = e.fieldErrors;
        _phoneTakenError = e.message.startsWith(_phoneTaken);
      });
      if (e.fieldErrors.isEmpty && !_phoneTakenError) showError(context, e);
    }
  }

  InputDecoration _decoration(String label, {String? error}) => InputDecoration(
    labelText: label,
    errorText: error,
    errorMaxLines: 3,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFDFF3EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFDFF3EF),
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: const Text('Đăng ký'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Mã xác nhận sẽ được gửi qua SMS tới số điện thoại bạn đăng ký.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF597677), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: _decoration(
                          'Số điện thoại',
                          error: _phoneTakenError
                              ? 'Số này đã đăng ký.'
                              : _serverErrors['phone'],
                        ),
                        validator: (value) {
                          final phone = (value ?? '').replaceAll(
                            RegExp(r'[\s().-]'),
                            '',
                          );
                          if (phone.isEmpty) {
                            return 'Vui lòng nhập số điện thoại';
                          }
                          if (!RegExp(
                            r'^(0\d{9}|\+84\d{9})$',
                          ).hasMatch(phone)) {
                            return 'Số điện thoại không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      if (_phoneTakenError)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const ForgotPasswordScreen(),
                                  ),
                                ),
                            style: TextButton.styleFrom(foregroundColor: _link),
                            child: const Text('Quên mật khẩu?'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration(
                          'Họ và tên',
                          error: _serverErrors['fullName'],
                        ),
                        validator: (value) {
                          final name = (value ?? '').trim();
                          if (name.isEmpty) return 'Vui lòng nhập họ và tên.';
                          if (name.length < 2) {
                            return 'Họ và tên phải có ít nhất 2 ký tự.';
                          }
                          if (!RegExp(
                            r'^[\p{L}\p{M}]+(?:\s+[\p{L}\p{M}]+)*$',
                            unicode: true,
                          ).hasMatch(name)) {
                            return 'Họ và tên chỉ được chứa chữ cái và khoảng trắng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _password,
                        obscureText: true,
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: _decoration(
                          'Mật khẩu',
                          error: _serverErrors['password'],
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) {
                            return 'Vui lòng nhập mật khẩu.';
                          }
                          if (password.length < 8 || password.length > 72) {
                            return 'Mật khẩu phải có từ 8 đến 72 ký tự.';
                          }
                          if (password.trim().isEmpty) {
                            return 'Mật khẩu không được chỉ chứa khoảng trắng.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirm,
                        obscureText: true,
                        decoration: _decoration('Nhập lại mật khẩu'),
                        validator: (value) => value != _password.text
                            ? 'Hai mật khẩu không khớp.'
                            : null,
                        onFieldSubmitted: (_) => _sendCode(),
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _busy ? null : _sendCode,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _busy ? 'Đang gửi mã...' : 'Gửi mã xác nhận qua SMS',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(foregroundColor: _link),
                        child: const Text('Đã có tài khoản? Đăng nhập'),
                      ),
                    ],
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
