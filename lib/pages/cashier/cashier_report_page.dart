import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/sales_provider.dart';
import '../../providers/auth_provider.dart';

class CashierReportPage extends StatefulWidget {
  const CashierReportPage({super.key});

  @override
  State<CashierReportPage> createState() => _CashierReportPageState();
}

class _CashierReportPageState extends State<CashierReportPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SalesProvider>(context, listen: false).fetchShiftReport()
    );
  }

  void _showCloseShiftDialog(double expectedTotal) {
    final actualCashCtrl = TextEditingController();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tutup Shift & Laporan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Total uang yang seharusnya ada di laci (Modal + Omset):", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(currency.format(expectedTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: actualCashCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Uang Fisik Aktual",
                hintText: "Hitung uang di laci...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (actualCashCtrl.text.isEmpty) return;
              try {
                double actual = double.parse(actualCashCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));

                await Provider.of<SalesProvider>(context, listen: false).closeShift(actual);

                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shift Ditutup. Sampai Jumpa!")));
                  // Otomatis Logout user
                  Provider.of<AuthProvider>(context, listen: false).logout();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
              }
            },
            child: const Text("Tutup Shift"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProv = Provider.of<SalesProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Hitung ringkasan lokal
    final double startCash = (salesProv.shiftReport?['start_cash'] as num?)?.toDouble() ?? 0;
    final double totalSales = (salesProv.shiftReport?['total_sales'] as num?)?.toDouble() ?? 0;
    final double expectedTotal = startCash + totalSales;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Laporan Shift", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: () => salesProv.fetchShiftReport(),
          )
        ],
      ),
      body: salesProv.isLoadingReport
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD RINGKASAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.lightBlueAccent]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Total Uang di Laci (Estimasi)", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(
                    currency.format(expectedTotal),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _whiteInfoItem("Modal Awal", currency.format(startCash)),
                      Container(width: 1, height: 30, color: Colors.white30),
                      _whiteInfoItem("Total Omset", currency.format(totalSales)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text("Aksi Shift", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),

            // TOMBOL TUTUP SHIFT
            ListTile(
              onTap: () => _showCloseShiftDialog(expectedTotal),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.white,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.exit_to_app, color: Colors.red),
              ),
              title: const Text("Tutup Shift (End of Day)", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Finalisasi laporan dan logout akun"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),

            const SizedBox(height: 12),

            // INFO SESI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Shift ID #${salesProv.shiftReport?['session_id'] ?? '-'} saat ini sedang aktif.",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _whiteInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}