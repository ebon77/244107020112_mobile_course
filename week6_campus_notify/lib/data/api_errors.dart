import 'package:dio/dio.dart';

class ApiErrorMapper {
  static String map(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Sesi Anda telah berakhir. Silakan login kembali.';
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Koneksi timeout. Periksa jaringan internet Anda.';
        case DioExceptionType.connectionError:
          return 'Tidak dapat terhubung ke server. Anda sedang offline.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return 'Terjadi kesalahan pada server (Kode: $statusCode).';
        case DioExceptionType.cancel:
          return 'Permintaan dibatalkan.';
        case DioExceptionType.unknown:
        default:
          return 'Terjadi masalah jaringan atau koneksi terputus.';
      }
    }
    return error?.toString() ?? 'Terjadi kesalahan yang tidak diketahui.';
  }
}
