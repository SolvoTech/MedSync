/// Base exception class for all app-level errors.
///
/// [code] is an internal English identifier (e.g. 'auth/invalid-password').
/// [message] is a user-facing Indonesian error message.
class AppException implements Exception {
  const AppException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() =>
      code != null ? 'AppException($code): $message' : 'AppException: $message';
}

/// Network-specific exception.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Tidak ada koneksi internet'])
    : super(code: 'network/offline');
}

/// Authentication-specific exception.
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Data not found exception.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Data tidak ditemukan'])
    : super(code: 'data/not-found');
}

/// Permission denied exception.
class PermissionDeniedException extends AppException {
  const PermissionDeniedException([super.message = 'Izin tidak diberikan'])
    : super(code: 'permission/denied');
}
