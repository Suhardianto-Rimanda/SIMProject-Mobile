import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import Providers
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/admin_provider.dart'; // <--- WAJIB DI-IMPORT
import 'providers/staff_provider.dart'; // <--- WAJIB DI-IMPORT (Jika ada)

import 'pages/auth/auth_wrapper.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),

        // --- PERBAIKAN: DAFTARKAN ADMIN PROVIDER DI SINI ---
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        // ---------------------------------------------------

        // Daftarkan juga StaffProvider jika Anda menggunakannya
        ChangeNotifierProvider(create: (_) => StaffProvider()),
      ],
      child: MaterialApp(
        title: 'SIM Project Flutter',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}