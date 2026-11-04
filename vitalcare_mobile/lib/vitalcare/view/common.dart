import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api.dart';

/// Shared bits for screens that load from the API: loading, empty and error
/// blocks in the app's colours, Vietnamese formatting, and opening links.

const _ink = Color(0xFF164E50);
const _primary = Color(0xFF008C91);
const _muted = Color(0xFF657E80);

/// The message to show for any failure.
String errorText(Object error) =>
    error is ApiException ? error.message : 'Đã có lỗi xảy ra. Vui lòng thử lại.';

void showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showError(BuildContext context, Object error) => showNotice(context, errorText(error));

class LoadingBlock extends StatelessWidget {
  const LoadingBlock({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Center(child: CircularProgressIndicator(color: _primary)),
  );
}

class ErrorBlock extends StatelessWidget {
  const ErrorBlock({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: _muted),
        const SizedBox(height: 12),
        Text(
          errorText(error),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5, color: _ink),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: _primary),
          child: const Text('Thử lại'),
        ),
      ],
    ),
  );
}

class EmptyBlock extends StatelessWidget {
  const EmptyBlock({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
    child: Column(
      children: [
        Icon(icon, size: 40, color: _primary),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: _muted),
        ),
      ],
    ),
  );
}

String two(int value) => value.toString().padLeft(2, '0');

/// `03/11`.
String dayMonth(DateTime date) => '${two(date.day)}/${two(date.month)}';

/// `03/11/2026`.
String fullDate(DateTime date) => '${dayMonth(date)}/${date.year}';

/// `09:41`.
String clockTime(DateTime time) => '${two(time.hour)}:${two(time.minute)}';

/// `Hôm nay`, `Hôm qua` or `03/11`.
String relativeDay(DateTime time, {DateTime? now}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final day = DateUtils.dateOnly(time);
  if (day == today) return 'Hôm nay';
  if (day == today.subtract(const Duration(days: 1))) return 'Hôm qua';
  return dayMonth(time);
}

/// `Hôm nay 09:41`.
String relativeTime(DateTime time) => '${relativeDay(time)} ${clockTime(time)}';

/// A decimal with a Vietnamese comma: `33.4` → `33,4`; whole numbers stay whole.
String decimal(double value, {int digits = 1}) {
  final whole = value == value.roundToDouble();
  return value.toStringAsFixed(whole && digits <= 1 ? 0 : digits).replaceAll('.', ',');
}

/// How long ago, for list subtitles.
String ago(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24 && DateUtils.isSameDay(time, DateTime.now())) {
    return '${diff.inHours} giờ trước';
  }
  return relativeTime(time);
}

/// Opens [url] outside the app (a video, a phone call). Says so when it cannot.
Future<void> openExternal(BuildContext context, Uri url) async {
  var opened = false;
  try {
    opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    showNotice(context, 'Không mở được liên kết trên thiết bị này.');
  }
}

Future<void> callPhone(BuildContext context, String phone) =>
    openExternal(context, Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));
