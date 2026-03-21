import 'app_exception.dart';
import 'failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

String toUserErrorMessage(
  Object error, {
  String fallback = 'Terjadi kesalahan. Silakan coba lagi.',
}) {
  if (error is AppException) {
    return error.message;
  }

  if (error is Failure) {
    return error.message;
  }

  if (error is sb.AuthException) {
    return _mapAuthError(error.code, error.message, fallback);
  }

  if (error is sb.PostgrestException) {
    final message = _cleanRawMessage(error.message);
    if (message != null) {
      return message;
    }
  }

  final parsedAuthApi = _parseAuthApiException(error.toString());
  if (parsedAuthApi != null) {
    return parsedAuthApi;
  }

  final cleaned = _cleanRawMessage(error.toString());
  if (cleaned != null) {
    return cleaned;
  }

  return fallback;
}

String _mapAuthError(String? code, String? message, String fallback) {
  final normalizedCode = code?.trim().toLowerCase();
  switch (normalizedCode) {
    case 'invalid_credentials':
    case 'invalid_login_credentials':
      return 'Email atau kata sandi salah.';
    case 'email_not_confirmed':
      return 'Email belum diverifikasi. Silakan cek inbox Anda.';
    case 'user_not_found':
      return 'Akun tidak ditemukan.';
    case 'email_exists':
    case 'user_already_exists':
      return 'Email sudah terdaftar. Silakan gunakan email lain.';
    case 'weak_password':
      return 'Kata sandi terlalu lemah. Gunakan kombinasi yang lebih kuat.';
    case 'over_request_rate_limit':
    case 'too_many_requests':
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
    case 'validation_failed':
      return 'Data yang dimasukkan tidak valid.';
    default:
      return _cleanRawMessage(message) ?? fallback;
  }
}

String? _parseAuthApiException(String raw) {
  if (!raw.contains('AuthApiException(')) {
    return null;
  }

  final codeMatch = RegExp(r'code:\s*([^,\)]+)').firstMatch(raw);
  final messageMatch = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
  final code = codeMatch?.group(1)?.trim();
  final message = messageMatch?.group(1)?.trim();
  return _mapAuthError(code, message, 'Autentikasi gagal. Silakan coba lagi.');
}

String? _cleanRawMessage(String? raw) {
  if (raw == null) {
    return null;
  }

  var message = raw.trim();
  if (message.isEmpty) {
    return null;
  }

  message = message
      .replaceFirst(RegExp(r'^Unhandled Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^Bad state:\s*'), '')
      .trim();

  final known = _mapKnownText(message);
  if (known != null) {
    return known;
  }

  if (message.startsWith('AuthApiException(')) {
    return _parseAuthApiException(message);
  }

  return message;
}

String? _mapKnownText(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('invalid login credentials')) {
    return 'Email atau kata sandi salah.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Email belum diverifikasi. Silakan cek inbox Anda.';
  }
  if (lower.contains('network') || lower.contains('socketexception')) {
    return 'Koneksi internet bermasalah. Silakan coba lagi.';
  }
  if (lower.contains('user not logged in')) {
    return 'Anda perlu login terlebih dahulu.';
  }
  if (lower.contains('http request failed') ||
      lower.contains('statuscode: 400') ||
      lower.contains('status code: 400')) {
    return 'Permintaan tidak valid. Silakan periksa data lalu coba lagi.';
  }
  if (lower.contains('statuscode: 401') || lower.contains('status code: 401')) {
    return 'Sesi Anda berakhir. Silakan login kembali.';
  }
  if (lower.contains('statuscode: 403') || lower.contains('status code: 403')) {
    return 'Anda tidak memiliki akses untuk aksi ini.';
  }
  if (lower.contains('statuscode: 404') || lower.contains('status code: 404')) {
    return 'Data tidak ditemukan.';
  }
  if (lower.contains('statuscode: 409') || lower.contains('status code: 409')) {
    return 'Data konflik dengan kondisi saat ini. Silakan muat ulang lalu coba lagi.';
  }
  if (lower.contains('statuscode: 422') || lower.contains('status code: 422')) {
    return 'Data yang dimasukkan tidak valid.';
  }
  if (lower.contains('statuscode: 500') ||
      lower.contains('status code: 500') ||
      lower.contains('statuscode: 502') ||
      lower.contains('status code: 502') ||
      lower.contains('statuscode: 503') ||
      lower.contains('status code: 503')) {
    return 'Server sedang bermasalah. Silakan coba lagi beberapa saat.';
  }
  if (message.length > 240) {
    return '${message.substring(0, 240)}...';
  }

  return null;
}
