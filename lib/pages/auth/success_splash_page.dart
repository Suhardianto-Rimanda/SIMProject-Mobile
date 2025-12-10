import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SuccessSplashPage extends StatefulWidget {
  const SuccessSplashPage({super.key});

  @override
  State<SuccessSplashPage> createState() => _SuccessSplashPageState();
}

class _SuccessSplashPageState extends State<SuccessSplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup Animasi Pop-up
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    _controller.forward();

    // Timer untuk pindah ke Home setelah 2 detik
    Timer(const Duration(seconds: 5), () {
      Provider.of<AuthProvider>(context, listen: false).completeSplash();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthProvider>(context, listen: false).userRole;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 80),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Login Berhasil!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Selamat datang kembali, ${userRole?.toUpperCase()}",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}