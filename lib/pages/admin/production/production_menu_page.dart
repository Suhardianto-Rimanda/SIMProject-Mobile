import 'package:flutter/material.dart';
import 'product_management_page.dart';
import 'ingredient_management_page.dart';

class ProductionMenuPage extends StatelessWidget {
  const ProductionMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            const Text(
                "Manajemen Produksi",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87
                )
            ),
            const SizedBox(height: 8),
            Text(
              "Kelola katalog menu makanan dan stok bahan baku gudang Anda di sini.",
              style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 32),

            // Section Label
            Text(
                "MENU UTAMA",
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                    letterSpacing: 1.2
                )
            ),
            const SizedBox(height: 16),

            // MENU 1: PRODUK & MENU
            _buildMenuCard(
              context,
              title: "Produk & Menu",
              subtitle: "Atur daftar menu, harga, dan resep.",
              icon: Icons.restaurant_menu_rounded,
              color: Colors.orange,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementPage()));
              },
            ),

            const SizedBox(height: 16),

            // MENU 2: BAHAN BAKU
            _buildMenuCard(
              context,
              title: "Bahan Baku",
              subtitle: "Cek stok gudang dan satuan beli.",
              icon: Icons.inventory_2_rounded,
              color: Colors.blue,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const IngredientManagementPage()));
              },
            ),

            // Spacer bawah untuk menghindari overflow di layar kecil
            const SizedBox(height: 40),
          ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5)
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),

                const SizedBox(width: 20),

                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          title,
                          style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87
                          )
                      ),
                      const SizedBox(height: 4),
                      Text(
                          subtitle,
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              height: 1.3
                          )
                      ),
                    ],
                  ),
                ),

                // Action Menu (Titik Tiga)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: Colors.grey[300]),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'open') onTap();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Row(
                        children: [
                          Icon(Icons.arrow_forward, size: 18, color: Colors.black54),
                          SizedBox(width: 12),
                          Text("Buka Menu"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}