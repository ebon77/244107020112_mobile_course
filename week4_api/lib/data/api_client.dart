import 'package:dio/dio.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl: '[https://jsonplaceholder.typicode.com_salah](https://jsonplaceholder.typicode.com_salah)',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},read
    ),
  );
  
  dio.interceptors.add(
    LogInterceptor(requestBody: true, responseBody: false),
  );
  
  return dio;
}