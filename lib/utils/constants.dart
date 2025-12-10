import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Mengambil URL dari .env
  static String get baseUrl => dotenv.env['BASE_URL'] ?? 'http://10.0.2.2';

  // Endpoint Auth
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';

  // Endpoint Sales/Products
  static const String menuEndpoint = '/sales/menu';
  static const String orderEndpoint = '/sales/orders';
}