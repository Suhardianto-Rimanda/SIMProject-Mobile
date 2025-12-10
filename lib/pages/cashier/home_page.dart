import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CashierHomePage extends StatelessWidget {
  const CashierHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kasir / POS"),
        backgroundColor: Colors.blueAccent, // Warna pembeda untuk Kasir
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.point_of_sale, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "Selamat Datang, Kasir!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("Menu: Input Transaksi, Buka Shift"),
          ],
        ),
      ),
    );
  }
}