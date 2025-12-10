import 'package:flutter/material.dart';
import 'product_management_page.dart';
import 'ingredient_management_page.dart';

class ProductionMenuPage extends StatelessWidget {
  const ProductionMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // FIX: Tambahkan SingleChildScrollView agar bisa di-scroll di layar kecil
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Manajemen Produksi", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Kelola katalog menu dan stok bahan baku gudang.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // MENU 1: PRODUK
              _buildMenuCard(
                context,
                title: "Produk & Menu",
                subtitle: "Kelola daftar menu makanan dan atur resep produksi.",
                icon: Icons.restaurant_menu,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementPage()));
                },
              ),

              const SizedBox(height: 16),

              // MENU 2: BAHAN BAKU (Placeholder dulu)
              _buildMenuCard(
                context,
                title: "Bahan Baku (Inventory)",
                subtitle: "Kelola stok bahan mentah, restock, dan opname.",
                icon: Icons.inventory_2,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const IngredientManagementPage()));
                },
              ),

              // Spasi tambahan agar tidak mepet bawah di layar kecil
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              // PERUBAHAN DI SINI: Ganti Arrow dengan PopupMenuButton
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onSelected: (value) {
                  if (value == 'open') onTap();
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, color: Colors.blue, size: 20),
                        SizedBox(width: 12),
                        Text('Buka Menu'),
                      ],
                    ),
                  ),
                  // Bisa tambah opsi lain nanti, misal "Lihat Laporan Cepat"
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}