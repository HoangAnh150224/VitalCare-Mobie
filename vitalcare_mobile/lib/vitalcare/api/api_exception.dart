/// A failed API call, already worded in Vietnamese for the screen.
///
/// The API answers `{message, errors: {field: message}}` in English. A 422's
/// own message is the generic "Validation failed"; the field message under it
/// says what to fix, so that becomes [message].
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.status,
    this.fieldErrors = const {},
    this.serverMessage,
  });

  /// Network failure, timeout or an unreadable answer.
  static const networkMessage =
      'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.';
  static const sessionExpiredMessage =
      'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';

  const ApiException.network()
    : message = networkMessage,
      status = null,
      fieldErrors = const {},
      serverMessage = null;

  final String message;

  /// HTTP status; null when the server could not be reached.
  final int? status;

  /// Vietnamese message per request field (`phone`, `otp`, `employeeId`, ...).
  final Map<String, String> fieldErrors;

  /// What the server said, untranslated, for logs.
  final String? serverMessage;

  bool get isNetwork => status == null;
  bool get isNotFound => status == 404;

  String? field(String name) => fieldErrors[name];

  /// Builds the exception from a decoded error body.
  factory ApiException.fromBody(int status, Object? body) {
    String? message;
    final fields = <String, String>{};
    if (body is Map) {
      final raw = body['message'];
      if (raw is String) message = raw;
      final errors = body['errors'];
      if (errors is Map) {
        errors.forEach((key, value) {
          if (value is String) {
            fields['$key'] = translateApiMessage(value);
          }
        });
      }
    }
    final firstField = fields.values.isEmpty ? null : fields.values.first;
    return ApiException(
      firstField ?? _headline(status, message),
      status: status,
      fieldErrors: fields,
      serverMessage: message,
    );
  }

  static String _headline(int status, String? message) {
    if (status == 401) {
      return message == null ||
              message.startsWith('Authentication is required') ||
              message.startsWith('Not signed in')
          ? sessionExpiredMessage
          : translateApiMessage(message);
    }
    if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
    if (status == 404) {
      return 'Không tìm thấy dữ liệu. Có thể nó đã bị xóa hoặc bạn không có quyền xem.';
    }
    if (status >= 500) {
      return 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
    }
    if (message == null || message.isEmpty) {
      return 'Không thực hiện được. Vui lòng thử lại.';
    }
    return translateApiMessage(message);
  }

  @override
  String toString() => 'ApiException($status): $message';
}

/// The API messages users meet, said again in Vietnamese, matched by how they
/// start (some carry a number or a date). Same approach as the web's
/// `translateRegistrationMessage` and `translateBillingMessage`.
const List<(String, String)> _messages = [
  // Signing in
  ('Incorrect phone number or password', 'Số điện thoại hoặc mật khẩu không đúng.'),
  ('This account is no longer active', 'Tài khoản đã ngừng hoạt động. Vui lòng liên hệ phòng khám.'),
  ('This account no longer exists', 'Tài khoản không còn tồn tại.'),
  ('Current password is required', 'Vui lòng nhập mật khẩu hiện tại.'),
  ('The current password is not correct', 'Mật khẩu hiện tại không đúng.'),
  ('New password must be between', 'Mật khẩu mới phải có từ 8 đến 100 ký tự.'),
  ('Refresh token is required', sessionExpiredText),
  // Phone numbers, codes, passwords (shared/api/registration.ts on the web)
  ('Phone number must be a Vietnamese number', 'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam, ví dụ: 0901234567 hoặc +84901234567.'),
  ('Not a valid Vietnamese phone number', 'Số điện thoại không hợp lệ. Vui lòng nhập số điện thoại Việt Nam, ví dụ: 0901234567 hoặc +84901234567.'),
  ('Phone number is required', 'Vui lòng nhập số điện thoại.'),
  ('Phone number is not valid', 'Số điện thoại không hợp lệ.'),
  ('Password is required', 'Vui lòng nhập mật khẩu.'),
  ('New password is required', 'Vui lòng nhập mật khẩu mới.'),
  ('Password must be between', 'Mật khẩu phải có từ 8 đến 72 ký tự.'),
  ('Password is too long', 'Mật khẩu quá dài. Hãy dùng ít chữ có dấu hơn.'),
  ('The code is required', 'Vui lòng nhập mã xác nhận.'),
  ('The code is the digits', 'Mã xác nhận là dãy số trong tin nhắn SMS.'),
  ('The code is incorrect', 'Mã xác nhận không đúng hoặc đã hết hạn.'),
  ('Please wait', 'Vừa gửi mã cho số này. Vui lòng đợi một chút trước khi yêu cầu mã mới.'),
  ('Too many codes have been requested from this network', 'Đã yêu cầu quá nhiều mã từ mạng này. Vui lòng thử lại sau.'),
  ('Too many codes', 'Đã gửi quá nhiều mã tới số này. Vui lòng thử lại sau.'),
  // Registering a visit (AppointmentServiceImpl)
  ('Pick one of your own profiles', 'Vui lòng chọn một hồ sơ của bạn.'),
  ("Fill in this profile's date of birth and gender", 'Hồ sơ này chưa có ngày sinh và giới tính. Vui lòng bổ sung hồ sơ trước khi đăng ký khám.'),
  ('A doctor is required', 'Vui lòng chọn bác sĩ.'),
  ('A date is required', 'Vui lòng chọn ngày khám.'),
  ('A reason for the visit is required', 'Vui lòng nhập lý do khám.'),
  ('Reason must be at most', 'Lý do khám tối đa 255 ký tự.'),
  ('The date cannot be in the past', 'Ngày khám không được ở trong quá khứ.'),
  ('Registration is open up to', 'Ngày khám vượt quá thời gian phòng khám nhận đăng ký.'),
  ("Pick one of the clinic's doctors", 'Vui lòng chọn một bác sĩ của phòng khám.'),
  ('That doctor is not tied to a clinic', 'Bác sĩ này chưa thuộc phòng khám nào.'),
  ('That doctor does not see patients on that day', 'Bác sĩ không khám vào ngày đã chọn.'),
  ('There is already a visit registered with that doctor on that day', 'Bạn đã đăng ký khám với bác sĩ này vào ngày đó.'),
  ('That doctor has no turn left on that day', 'Bác sĩ đã hết lượt khám vào ngày đã chọn.'),
  ("That doctor's clinic is not taking visits", 'Phòng khám của bác sĩ này đang tạm ngừng nhận khám.'),
  ('The appointment is already with that doctor on that day', 'Lịch hẹn đã ở đúng bác sĩ và ngày này.'),
  ('Only a registered appointment can be', 'Chỉ thay đổi được lịch hẹn đang ở trạng thái đã đăng ký.'),
  ('An appointment can only be', 'Chỉ được đổi hoặc hủy lịch chậm nhất 2 giờ trước giờ khám dự kiến.'),
  ('The examination fee for that appointment is not paid yet', 'Lượt khám chưa được thanh toán phí khám.'),
  // Sharing (Sharing.java)
  ("Enter the caregiver's phone number", 'Vui lòng nhập số điện thoại người nhận.'),
  ('Enter an emergency contact number', 'Vui lòng nhập số điện thoại liên hệ khẩn cấp.'),
  ('No VitalCare account uses that number', 'Số điện thoại này chưa có tài khoản VitalCare. Hãy nhờ người thân đăng ký trước.'),
  ('Choose somebody other than yourself', 'Hãy chọn người khác, không phải chính bạn.'),
  ('Enter a Vietnamese phone number', 'Vui lòng nhập số điện thoại Việt Nam hợp lệ.'),
  ('The end of access must be in the future', 'Ngày kết thúc chia sẻ phải ở tương lai.'),
  ('That caregiver already has access', 'Người này đang được chia sẻ. Hãy thu hồi rồi chia sẻ lại nếu muốn thay đổi.'),
  ('At most two caregivers may have access', 'Chỉ chia sẻ được tối đa 2 người cùng lúc. Hãy thu hồi một người trước.'),
  ('Only access in force can be changed', 'Quyền chia sẻ đã hết hạn hoặc bị thu hồi. Hãy chia sẻ lại.'),
  ('Already revoked', 'Quyền chia sẻ này đã được thu hồi.'),
  // Devices (MyDevices.java)
  ('This device is paired with another phone', 'Thiết bị đang ghép với điện thoại khác. Hãy hủy ghép trên máy đó trước.'),
  ('At most 500 readings per upload', 'Mỗi lần gửi tối đa 500 bản ghi.'),
  // Messages (SupportChat.java)
  ('Write a message', 'Vui lòng nhập tin nhắn.'),
  ('A message must be at most', 'Tin nhắn tối đa 2000 ký tự.'),
  ('Pick a clinic', 'Vui lòng chọn phòng khám.'),
  ('Pick one of the clinics', 'Vui lòng chọn phòng khám.'),
  ('That clinic is not taking messages', 'Phòng khám này đang tạm ngừng nhận tin nhắn.'),
  ('That clinic does not look after this patient', 'Phòng khám này không theo dõi người bệnh này.'),
  // Vital signs (VitalViews.java)
  ('Times must be ISO-8601', 'Khoảng thời gian không hợp lệ.'),
  ('The start must be before the end', 'Thời điểm bắt đầu phải trước thời điểm kết thúc.'),
  ('At most 92 days at a time', 'Chỉ xem được tối đa 92 ngày mỗi lần.'),
  // Shared by every endpoint
  ('You do not have permission', 'Bạn không có quyền thực hiện thao tác này.'),
  ('This record was just changed by someone else', 'Dữ liệu vừa được người khác thay đổi. Tải lại rồi thử lại.'),
  ('Authentication is required', sessionExpiredText),
];

const sessionExpiredText = ApiException.sessionExpiredMessage;

/// One API message in Vietnamese; unknown ones are returned as written.
String translateApiMessage(String message) {
  for (final (prefix, vi) in _messages) {
    if (message.startsWith(prefix)) return vi;
  }
  return message;
}
