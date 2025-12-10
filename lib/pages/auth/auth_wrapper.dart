import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Provider
import '../../providers/auth_provider.dart';

// Import Halaman Login
import 'login_page.dart';

// Import Halaman Home Berdasarkan Role
import '../admin/home_page.dart';
import '../cashier/home_page.dart';
import '../kitchen/home_page.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Fungsi untuk mengecek apakah ada token tersimpan di HP
  Future<void> _checkSession() async {
    // tryAutoLogin akan mengisi variable userRole & isAuthenticated di Provider
    await Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();

    // Pastikan widget masih tertempel di tree sebelum setState
    if (mounted) {
      setState(() {
        _isCheckingSession = false; // Loading selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. TAMPILKAN LOADING SAAT CEK SESI (SPLASH SCREEN)
    if (_isCheckingSession) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Memuat sesi..."),
            ],
          ),
        ),
      );
    }

    // 2. LISTEN PERUBAHAN AUTH STATE
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {

        // A. JIKA BELUM LOGIN -> KE LOGIN PAGE
        if (!auth.isAuthenticated) {
          return const LoginPage();
        }

        // B. JIKA SUDAH LOGIN -> CEK ROLE USER
        // Pastikan string role ini SAMA PERSIS dengan respon backend Flask ('admin', 'cashier', 'kitchen')
        switch (auth.userRole) {
          case 'admin':
            return const AdminHomePage();
          case 'cashier':
            return const CashierHomePage();
          case 'kitchen':
            return const KitchenHomePage();

        // C. JIKA ROLE TIDAK DIKENALI (SAFETY FALLBACK)
          default:
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text("Role '${auth.userRole}' tidak dikenali!"),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Paksa Logout agar user tidak stuck
                        auth.logout();
                      },
                      child: const Text("Logout & Login Ulang"),
                    )
                  ],
                ),
              ),
            );
        }
      },
    );
  }
}