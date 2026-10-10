import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'verification_pin_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  static const _primary = Color(0xFF008C91);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF007C80);

  void _sendRecoverySms() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerificationPinScreen(
          phoneNumber: _phoneController.text.replaceAll(
            RegExp(r'[\s().-]'),
            '',
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
          centerTitle: true,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Quay lại đăng nhập',
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
                            'Quên mật khẩu?',
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
                            'Nhập số điện thoại đã đăng ký để nhận mã xác nhận qua SMS.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Color(0xFF597677),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Số điện thoại',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            autocorrect: false,
                            enableSuggestions: false,
                            cursorColor: _link,
                            style: const TextStyle(fontSize: 16, color: _ink),
                            decoration: InputDecoration(
                              hintText: 'Nhập số điện thoại',
                              hintStyle: const TextStyle(
                                color: Color(0xFF597677),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: _link,
                                size: 22,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFFCCDADC),
                                ),
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
                            onFieldSubmitted: (_) => _sendRecoverySms(),
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _sendRecoverySms,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              elevation: 0,
                              shadowColor: const Color(0x40008C91),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(56),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Gửi mã xác nhận qua SMS',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: _link,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: const Text(
                              'Quay lại đăng nhập',
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
    );
  }
}
