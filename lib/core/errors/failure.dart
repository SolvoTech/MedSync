/// Represents a domain-level failure from a repository or service call.
///
/// Use [Failure] to propagate error info from the data layer up to the UI
/// without throwing exceptions across layer boundaries.
sealed class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => 'Failure($code): $message';
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Terjadi kesalahan server. Silakan coba lagi.',
  ]) : super(code: 'server');
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Gagal memuat data. Silakan coba lagi.'])
    : super(code: 'cache');
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Koneksi internet bermasalah. Silakan coba lagi.',
  ]) : super(code: 'network');
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Autentikasi gagal. Silakan coba lagi.'])
    : super(code: 'auth');
}

class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Data tidak valid. Silakan periksa kembali input Anda.',
  ]) : super(code: 'validation');
}
