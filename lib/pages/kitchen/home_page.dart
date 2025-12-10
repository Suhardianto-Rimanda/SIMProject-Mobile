import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class KitchenHomePage extends StatelessWidget {
  const KitchenHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dapur / Kitchen Display"),
        backgroundColor: Colors.orangeAccent, // Warna pembeda untuk Dapur
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
            Icon(Icons.restaurant, size: 80, color: Colors.orangeAccent),
            SizedBox(height: 20),
            Text(
              "Selamat Datang, Chef!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text("Menu: Cek Stok, List Pesanan Masak"),
          ],
        ),
      ),
    );
  }
}