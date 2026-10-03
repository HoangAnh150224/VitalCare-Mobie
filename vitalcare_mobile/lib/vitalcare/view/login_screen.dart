import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  bool _rememberLogin = false;

  static const _primary = Color(0xFF00C4C7);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF007C80);

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng đăng nhập chưa được kết nối máy chủ.'),
      ),
    );
  }

  InputDecoration _decoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF637F80)),
      filled: true,
      fillColor: const Color(0xFFF0FBFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC9EAEA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFC9EAEA)),
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
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/images/logo.jpg',
                          height: 150,
                          fit: BoxFit.contain,
                          semanticLabel: 'VitalCare',
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Đăng nhập',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 36),
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
                          cursorColor: _link,
                          decoration: _decoration('Nhập số điện thoại'),
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
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
                          cursorColor: _link,
                          decoration: _decoration(
                            'Nhập mật khẩu',
                            suffix: TextButton(
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              child: Text(
                                _showPassword ? 'Ẩn' : 'Hiện',
                                style: const TextStyle(color: _link),
                              ),
                            ),
                          ),
                          obscureText: !_showPassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (value) => value == null || value.isEmpty
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
                                  checkColor: _ink,
                                  onChanged: (value) => setState(
                                    () => _rememberLogin = value ?? false,
                                  ),
                                  semanticLabel: 'Ghi nhớ đăng nhập',
                                ),
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _rememberLogin = !_rememberLogin,
                                  ),
                                  child: const Text('Ghi nhớ đăng nhập'),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Quên mật khẩu?'),
                                  content: const Text(
                                    'Chức năng khôi phục mật khẩu chưa được kết nối máy chủ.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
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
                        const SizedBox(height: 28),
                        FilledButton(
                          onPressed: _login,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: _ink,
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
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
    );
  }
}
