import 'package:dio/dio.dart';
import 'package:tripx_frontend/api/api_constants.dart';

// Create a single, pre-configured Dio instance
final dio = Dio(
  BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ),
);
