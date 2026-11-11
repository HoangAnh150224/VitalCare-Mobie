import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/api.dart';
import 'common.dart';

/// The SMS code step, for password recovery or, with [registration], for
/// creating an account (UC-04).
class VerificationPinScreen extends StatefulWidget {
  const VerificationPinScreen({
    super.key,
    required this.phoneNumber,
    this.registration,
  });

  final String phoneNumber;

  /// The account being registered; null for password recovery.
  final ({String fullName, String password})? registration;

  @override
  State<VerificationPinScreen> createState() => _VerificationPinScreenState();
}

class _VerificationPinScreenState extends State<VerificationPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinKey = GlobalKey<FormFieldState<String>>();
  final _digits = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  static const _primary = Color(0xFF00777C);
  static const _ink = Color(0xFF164E50);
  static const _link = Color(0xFF00777C);
  bool _busy = false;
  bool _resending = false;
  String? _otpError;

  String get _code => _digits.map((c) => c.text).join();

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
    if (_otpError != null) setState(() => _otpError = null);
    _pinKey.currentState?.didChange(_code);
  }

  Widget _buildPinInput() {
    return FormField<String>(
      key: _pinKey,
      validator: (_) => _digits.every((c) => RegExp(r'^\d$').hasMatch(c.text))
          ? null
          : 'Vui lòng nhập đủ 6 chữ số',
      builder: (field) {
        final error = field.errorText ?? _otpError;
        return Column(
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
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: error != null
                                ? Theme.of(context).colorScheme.error
                                : const Color(0xFFA9C1BE),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: _primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final auth = Api.instance.auth;
      await (widget.registration == null
          ? auth.requestResetCode(widget.phoneNumber)
          : auth.requestRegistrationCode(widget.phoneNumber));
      if (mounted) showNotice(context, 'Đã gửi lại mã xác nhận qua SMS.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() => _otpError = null);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final code = _code;
    final registration = widget.registration;
    if (registration != null) return _register(registration, code);
    setState(() => _busy = true);
    try {
      await Api.instance.auth.checkResetCode(widget.phoneNumber, code);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpError = e.field('otp');
      });
      if (_otpError == null) showError(context, e);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final done = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NewPasswordDialog(phone: widget.phoneNumber, otp: code),
    );
    if (done == true && mounted) {
      showNotice(
        context,
        'Đã đặt lại mật khẩu. Vui lòng đăng nhập bằng mật khẩu mới.',
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// UC-04: the code is checked, the profiles with the number are offered to
  /// claim one (or "not me"), then the account is created.
  Future<void> _register(
    ({String fullName, String password}) registration,
    String code,
  ) async {
    final auth = Api.instance.auth;
    setState(() => _busy = true);
    try {
      final matches = await auth.checkRegistrationCode(
        widget.phoneNumber,
        code,
      );
      int? claim;
      if (matches.isNotEmpty) {
        if (!mounted) return;
        // The id picked, or -1 for "not me"; null when the dialog is closed.
        final picked = await showDialog<int>(
          context: context,
          builder: (_) => _ClaimProfileDialog(matches: matches),
        );
        if (picked == null) {
          if (mounted) setState(() => _busy = false);
          return;
        }
        claim = picked < 0 ? null : picked;
      }
      await auth.register(
        phone: widget.phoneNumber,
        otp: code,
        fullName: registration.fullName,
        password: registration.password,
        claimProfileId: claim,
      );
      if (!mounted) return;
      showNotice(context, 'Đăng ký thành công. Vui lòng đăng nhập.');
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _otpError = e.field('otp');
      });
      if (_otpError == null) showError(context, e);
    }
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
                              // Smaller on a phone on its side, where the full-size logo takes a third of the height.
                              child: SizedBox.square(
                                dimension:
                                    MediaQuery.sizeOf(context).height < 500
                                    ? 64
                                    : 104,
                                child: FittedBox(
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
                            Text(
                              widget.registration == null
                                  ? 'Nhập mã xác nhận gồm 6 chữ số từ SMS để khôi phục mật khẩu cho số điện thoại'
                                  : 'Nhập mã xác nhận gồm 6 chữ số từ SMS để đăng ký tài khoản cho số điện thoại',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFF3E5658),
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
                              onPressed: _busy ? null : _verify,
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
                              child: Text(
                                _busy ? 'Đang kiểm tra...' : 'Xác nhận',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Bạn chưa nhận được mã?',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF3E5658)),
                            ),
                            TextButton(
                              onPressed: _resending ? null : _resend,
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

/// UC-04 step 10: the profiles the clinic has with the number, masked; the
/// person picks their own (its id) or "not me" (-1).
class _ClaimProfileDialog extends StatefulWidget {
  const _ClaimProfileDialog({required this.matches});

  final List<ProfileMatch> matches;

  @override
  State<_ClaimProfileDialog> createState() => _ClaimProfileDialogState();
}

class _ClaimProfileDialogState extends State<_ClaimProfileDialog> {
  int? _picked;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Chọn hồ sơ của bạn'),
    content: SingleChildScrollView(
      child: RadioGroup<int>(
        groupValue: _picked,
        onChanged: (value) => setState(() => _picked = value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phòng khám đã có hồ sơ với số điện thoại này. Chọn hồ sơ của chính bạn; '
              'các hồ sơ còn lại sẽ được thêm vào tài khoản là người thân.',
            ),
            const SizedBox(height: 8),
            for (final match in widget.matches)
              RadioListTile<int>(value: match.id, title: Text(match.label)),
            const RadioListTile<int>(
              value: -1,
              title: Text('Không phải tôi — tạo hồ sơ mới'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _picked == null
            ? null
            : () => Navigator.pop(context, _picked),
        child: const Text('Tạo tài khoản'),
      ),
    ],
  );
}

/// The last step of recovery: the new password, sent with the checked code.
class _NewPasswordDialog extends StatefulWidget {
  const _NewPasswordDialog({required this.phone, required this.otp});

  final String phone;
  final String otp;

  @override
  State<_NewPasswordDialog> createState() => _NewPasswordDialogState();
}

class _NewPasswordDialogState extends State<_NewPasswordDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await Api.instance.auth.resetPassword(
        widget.phone,
        widget.otp,
        _password.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.field('newPassword') ?? e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Đặt mật khẩu mới'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                errorText: _error,
                errorMaxLines: 3,
              ),
              validator: (value) => (value ?? '').length < 8
                  ? 'Mật khẩu phải có từ 8 đến 72 ký tự.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nhập lại mật khẩu mới',
              ),
              validator: (value) => value != _password.text
                  ? 'Mật khẩu nhập lại không khớp.'
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context, false),
        child: const Text('Hủy'),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(_busy ? 'Đang lưu...' : 'Lưu mật khẩu'),
      ),
    ],
  );
}
