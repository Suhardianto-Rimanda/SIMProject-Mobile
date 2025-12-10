import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Untuk Debouncer

import '../../providers/kitchen_provider.dart';
import '../../models/kitchen_model.dart';

class KitchenStockPage extends StatefulWidget {
  const KitchenStockPage({super.key});

  @override
  State<KitchenStockPage> createState() => _KitchenStockPageState();
}

class _KitchenStockPageState extends State<KitchenStockPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<KitchenProvider>(context, listen: false).fetchStocks()
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi Pencarian dengan Delay (Debounce)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      Provider.of<KitchenProvider>(context, listen: false).fetchStocks(query: query);
    });
  }

  // --- DIALOG RESTOCK ---
  void _showRestockDialog(KitchenStockItem item) {
    final qtyCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.add_shopping_cart, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text("Restock ${item.name}", style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
              child: Text(
                "Satuan Beli: ${item.purchaseUnit}\nKonversi: 1 ${item.purchaseUnit} = ${item.conversionRate} ${item.unit}",
                style: TextStyle(color: Colors.blue[800], fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: "Jumlah Beli (${item.purchaseUnit})",
                  border: const OutlineInputBorder(),
                  hintText: "Misal: 5"
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: "Total Harga Beli (Rp)",
                  border: OutlineInputBorder(),
                  hintText: "Total harga belanjaan"
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () async {
              if (qtyCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

              double buyQty = double.parse(qtyCtrl.text);
              double totalQtyBase = buyQty * item.conversionRate;
              double pricePerUnitBase = double.parse(priceCtrl.text) / totalQtyBase;

              try {
                await Provider.of<KitchenProvider>(context, listen: false).restockIngredient(
                    item.id,
                    totalQtyBase,
                    pricePerUnitBase
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil restock ${item.name}")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            },
            child: const Text("Simpan Stok"),
          )
        ],
      ),
    );
  }

  // --- DIALOG OPNAME ---
  void _showOpnameDialog(KitchenStockItem item) {
    final qtyCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.tune, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text("Opname ${item.name}", style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sesuaikan stok manual jika ada selisih, rusak, atau terbuang.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                  labelText: "Perubahan Stok (${item.unit})",
                  border: const OutlineInputBorder(),
                  helperText: "Gunakan minus (-) untuk mengurangi",
                  hintText: "Contoh: -500"
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: "Alasan", border: OutlineInputBorder(), hintText: "Misal: Busuk, Tumpah"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () async {
              if (qtyCtrl.text.isEmpty) return;
              try {
                await Provider.of<KitchenProvider>(context, listen: false).adjustStock(
                    item.id,
                    double.parse(qtyCtrl.text),
                    reasonCtrl.text.isEmpty ? "Adjustment" : reasonCtrl.text
                );
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Stok Disesuaikan!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            },
            child: const Text("Simpan"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<KitchenProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50], // Background utama tetap abu-abu muda
      body: Column(
        children: [
          // --- HEADER & SEARCH (Updated Style) ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white, // GANTI DARI DARK (0xFF1E293B) KE PUTIH
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    "Manajemen Stok",
                    style: TextStyle(
                        color: Colors.black87, // Teks jadi gelap
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    )
                ),
                const Text(
                    "Kontrol bahan baku dapur & gudang",
                    style: TextStyle(
                        color: Colors.grey, // Subtitle jadi abu-abu
                        fontSize: 12
                    )
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(color: Colors.black87), // Input teks gelap
                        decoration: InputDecoration(
                          hintText: "Cari bahan...",
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[100], // Background input jadi abu-abu muda
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => prov.fetchStocks(),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text("Refresh"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                    )
                  ],
                )
              ],
            ),
          ),

          // --- LIST STOCK ---
          Expanded(
            child: prov.isLoadingStocks
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.stocks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final item = prov.stocks[i];
                return _buildStockCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(KitchenStockItem item) {
    Color statusColor = Colors.green;
    String statusText = "AMAN";
    if (item.status == 'Habis' || item.status == 'HABIS!') {
      statusColor = Colors.red;
      statusText = "HABIS";
    } else if (item.status == 'Menipis') {
      statusColor = Colors.orange;
      statusText = "MENIPIS";
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Kartu tetap putih
        borderRadius: BorderRadius.circular(8),
        // Update border agar lebih subtle di background terang
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1), // Shadow lebih lembut
              blurRadius: 6,
              offset: const Offset(0, 2)
          )
        ],
      ),
      child: Column(
        children: [
          // Header Kartu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text("#${item.id}", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        item.name,
                        style: const TextStyle(
                            color: Colors.black87, // Nama item jadi hitam
                            fontWeight: FontWeight.bold,
                            fontSize: 15
                        )
                    )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.5))
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),

          // Detail Grid
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Warna value disesuaikan agar terbaca di background putih
                _detailColumn("Stok (Dasar)", "${item.stock} ${item.unit}", Colors.green[700]!),
                _detailColumn("Satuan Beli", item.purchaseUnit, Colors.black54),
                // FIX: Gunakan .conversionRate jika avgCost tidak ada
                _detailColumn("Konversi", "x ${item.conversionRate}", Colors.black54),
              ],
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRestockDialog(item),
                    icon: const Icon(Icons.add_shopping_cart, size: 16),
                    label: const Text("Restock"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600], // Biru sedikit lebih terang
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOpnameDialog(item),
                    icon: const Icon(Icons.tune, size: 16),
                    label: const Text("Opname"),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700], // Orange lebih gelap untuk teks
                        side: BorderSide(color: Colors.orange[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _detailColumn(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}