class ApiConstants {
  // For Android Emulator, use 10.0.2.2 to connect to localhost on the host machine.
  // For physical devices, replace with your computer's actual IP address on the same Wi-Fi network.
  static const String _serverRoot = 'http://10.236.176.96:5000';
  static const String baseUrl = '$_serverRoot/api';

  // Static files base URL (for images, etc.)
  static const String staticFilesUrl = '$_serverRoot/public';

  // Auth Endpoints
  static const String registerUrl = '/auth/register';
  static const String loginUrl = '/auth/login';

  // Trip Endpoints (relative to baseUrl)
  static const String tripsUrl = '/trips';
  static const String destinationsUrl = '/destinations';

  // It's better practice to combine the baseUrl and the endpoint in your repository/service layer.
  // Example:
  // final dio = Dio();
  // final response = await dio.post('${ApiConstants.baseUrl}${ApiConstants.registerUrl}', data: ...);
}
