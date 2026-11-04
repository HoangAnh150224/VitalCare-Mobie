import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import 'common.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _rememberLogin = false;
  bool _busy = false;
  Map<String, String> _serverErrors = const {};

  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF007C80);

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() => _serverErrors = const {});
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await Api.instance.auth.login(
        _phone.text.replaceAll(RegExp(r'[\s().-]'), ''),
        _password.text,
        remember: _rememberLogin,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _serverErrors = e.fieldErrors;
      });
      if (e.fieldErrors.isEmpty) showError(context, e);
    }
  }

  InputDecoration _decoration(
    String hint, {
    required IconData icon,
    Widget? suffix,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      hintStyle: const TextStyle(color: Color(0xFF778A91), fontSize: 15),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      suffixIcon: suffix,
      prefixIcon: Icon(icon, color: _link, size: 22),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFF6FBF9),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/anh_nen.jpg'),
              fit: BoxFit.cover,
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
                            const SizedBox(height: 24),
                            const Text(
                              'Đăng nhập',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.25,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Số điện thoại',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _phone,
                              onChanged: (_) {
                                if (_serverErrors.isNotEmpty) {
                                  setState(() => _serverErrors = const {});
                                }
                              },
                              cursorColor: _link,
                              style: const TextStyle(fontSize: 16, color: _ink),
                              decoration: _decoration(
                                'Nhập số điện thoại',
                                icon: Icons.phone_outlined,
                                error: _serverErrors['phone'],
                              ),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
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
                            const SizedBox(height: 24),
                            const Text(
                              'Mật khẩu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _password,
                              onChanged: (_) {
                                if (_serverErrors.isNotEmpty) {
                                  setState(() => _serverErrors = const {});
                                }
                              },
                              cursorColor: _link,
                              style: const TextStyle(fontSize: 16, color: _ink),
                              decoration: _decoration(
                                'Nhập mật khẩu',
                                icon: Icons.lock_outline_rounded,
                                error: _serverErrors['password'],
                                suffix: IconButton(
                                  tooltip: _showPassword
                                      ? 'Ẩn mật khẩu'
                                      : 'Hiện mật khẩu',
                                  onPressed: () => setState(
                                    () => _showPassword = !_showPassword,
                                  ),
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _link,
                                  ),
                                ),
                              ),
                              obscureText: !_showPassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: const [AutofillHints.password],
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _login(),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Vui lòng nhập mật khẩu'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _rememberLogin,
                                      activeColor: _primary,
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      onChanged: (value) => setState(
                                        () => _rememberLogin = value ?? false,
                                      ),
                                      semanticLabel: 'Ghi nhớ đăng nhập',
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _rememberLogin = !_rememberLogin,
                                      ),
                                      child: const Text(
                                        'Ghi nhớ đăng nhập',
                                        style: TextStyle(color: _ink),
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  ),
                                  child: const Text(
                                    'Quên mật khẩu?',
                                    style: TextStyle(
                                      color: _link,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _login,
                              style: FilledButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(56),
                                elevation: 0,
                                shadowColor: const Color(0x40008C91),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_busy) ...[
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  const Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
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
