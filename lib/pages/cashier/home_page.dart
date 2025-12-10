import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sales_provider.dart';
import 'transaction_page.dart';
import 'order_history_page.dart';
import 'cashier_report_page.dart';

class CashierHomePage extends StatefulWidget {
  const CashierHomePage({super.key});

  @override
  State<CashierHomePage> createState() => _CashierHomePageState();
}

class _CashierHomePageState extends State<CashierHomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  Future<void> _checkShiftStatus() async {
    final salesProv = Provider.of<SalesProvider>(context, listen: false);
    await salesProv.checkShiftStatus();

    if (!salesProv.isShiftOpen && mounted) {
      _showOpenShiftDialog();
    }
  }

  void _showOpenShiftDialog() {
    final TextEditingController amountCtrl = TextEditingController();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_rounded, color: Colors.orange, size: 40),
            const SizedBox(height: 16),
            const Text("Selamat Pagi!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Masukkan modal awal kasir hari ini", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
              decoration: InputDecoration(
                hintText: "Rp 0",
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (amountCtrl.text.isEmpty) return;
                  try {
                    double amount = double.parse(amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                    await Provider.of<SalesProvider>(context, listen: false).openShift(amount);
                    if (mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Shift Dibuka dengan Modal ${currency.format(amount)}")));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Buka Shift Sekarang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.pop(ctx);
                },
                child: const Text("Batal & Logout", style: TextStyle(color: Colors.grey))
            )
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // HAPUS listener SalesProvider di level build ini agar tidak rebuild saat fetch data
    // final salesProv = Provider.of<SalesProvider>(context); <-- HAPUS INI

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Kasir / POS"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
          ),
        ],
      ),
      // PERBAIKAN: Jangan gunakan logic if(isLoading) disini.
      // Langsung return IndexedStack agar halaman tidak didestroy saat loading.
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          TransactionPage(), // Halaman ini menangani loading-nya sendiri
          OrderHistoryPage(),
          CashierReportPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Transaksi'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.summarize), label: 'Laporan'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}