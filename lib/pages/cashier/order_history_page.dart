import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PDF & Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Namespace 'pw'
import 'package:printing/printing.dart';

import '../../providers/sales_provider.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SalesProvider>(context, listen: false).fetchOrderHistory()
    );
  }

  // --- LOGIKA CETAK PDF STRUK (DARI RIWAYAT) ---
  Future<void> _printReceiptFromHistory({
    required String invoice,
    required String customer,
    required String cashier,
    required List<dynamic> items,
    required double total,
    required String method,
    required String dateStr,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            // PERBAIKAN: Gunakan pw.CrossAxisAlignment
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // PERBAIKAN: Gunakan pw.FontWeight
              pw.Text("UMKM KULINER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text("Jl. Bathin Alam No. 1", style: const pw.TextStyle(fontSize: 10)),
              pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // PERBAIKAN: Gunakan pw.MainAxisAlignment pada setiap pw.Row
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Inv: $invoice", style: const pw.TextStyle(fontSize: 10)),
                  ]
              ),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Plg: $customer", style: const pw.TextStyle(fontSize: 10)),
                  ]
              ),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Ksr: $cashier", style: const pw.TextStyle(fontSize: 10)),
                  ]
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Items Loop
              ...items.map((item) {
                return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item['product'], style: const pw.TextStyle(fontSize: 10)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text("${item['qty']} x ${currency.format(item['price'])}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(currency.format(item['subtotal']), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ]
                );
              }),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(currency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 4),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Metode", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(method.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text("Terima Kasih!", style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
              pw.Text("(Reprint)", style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Struk_$invoice.pdf',
    );
  }

  // --- DIALOG DETAIL PESANAN ---
  void _showOrderDetailDialog(String invoiceNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: _apiService.get('/sales/orders/$invoiceNo'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text("Gagal memuat detail: ${snapshot.error}", textAlign: TextAlign.center),
                );
              }

              final data = snapshot.data as Map<String, dynamic>;
              final items = data['items'] as List;
              final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

              // Ambil data untuk cetak
              final String customerName = data['customer'] ?? 'Pelanggan';
              final String cashierName = data['cashier'] ?? 'Kasir';
              final String dateStr = data['date'] ?? '-';
              final double total = (data['total'] as num).toDouble();
              final String paymentMethod = data['payment'] ?? 'cash';

              final screenHeight = MediaQuery.of(context).size.height;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Detail $invoiceNo",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      ],
                    ),
                  ),

                  // List Items
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: screenHeight * 0.5,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                              child: Text("${item['qty']}x", style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['product'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    "@ ${currency.format(item['price'])}",
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              currency.format(item['subtotal']),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Footer Summary & Action
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Akhir", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              currency.format(total),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Tombol Cetak Struk (Hanya jika Lunas)
                        if (paymentMethod != 'pending')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _printReceiptFromHistory(
                                    invoice: invoiceNo,
                                    customer: customerName,
                                    cashier: cashierName,
                                    items: items,
                                    total: total,
                                    method: paymentMethod,
                                    dateStr: dateStr
                                );
                              },
                              icon: const Icon(Icons.print),
                              label: const Text("Cetak Struk Ulang"),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: null, // Disabled
                              icon: const Icon(Icons.print_disabled),
                              label: const Text("Bayar Dulu untuk Cetak"),
                            ),
                          )
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showPaymentDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Lunasi ${order.invoiceNo}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih metode pembayaran pelunasan:"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _paymentBtn(ctx, order.invoiceNo, "Tunai", "cash", Icons.money),
                _paymentBtn(ctx, order.invoiceNo, "QRIS", "qris", Icons.qr_code),
                _paymentBtn(ctx, order.invoiceNo, "Transfer", "transfer", Icons.account_balance),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _paymentBtn(BuildContext ctx, String invoice, String label, String method, IconData icon) {
    return Column(
      children: [
        IconButton.filled(
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await Provider.of<SalesProvider>(context, listen: false).payPendingOrder(invoice, method);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pelunasan Berhasil!")));
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
            }
          },
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.all(12),
          ),
          iconSize: 28,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProv = Provider.of<SalesProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Riwayat Pesanan", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => salesProv.fetchOrderHistory(),
          )
        ],
      ),
      body: salesProv.isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : salesProv.orderHistory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text("Belum ada riwayat transaksi", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: salesProv.orderHistory.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) {
          final order = salesProv.orderHistory[i];
          return _buildOrderCard(order, currency);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, NumberFormat currency) {
    final bool isUnpaid = order.isUnpaid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isUnpaid ? Border.all(color: Colors.orange, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // INVOICE CLICKABLE
                      InkWell(
                        onTap: () => _showOrderDetailDialog(order.invoiceNo),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                order.invoiceNo,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent, decoration: TextDecoration.underline),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.info_outline, size: 16, color: Colors.blueAccent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM HH:mm').format(order.transactionDate),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadges(order),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[100],
                        child: const Icon(Icons.person, size: 18, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(order.totalAmount),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isUnpaid ? Colors.orange[800] : Colors.black87
                  ),
                ),
              ],
            ),
            if (isUnpaid) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPaymentDialog(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Lunasi Sekarang"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadges(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (order.isUnpaid)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange)
            ),
            child: const Text("PROSES", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
          )
        else
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                // DEFAULT MENAMPILKAN "LUNAS" JIKA METHOD BUKAN PENDING
                Text(
                    "DONE (${order.paymentMethod.toUpperCase()})",
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)
                ),
              ],
            ),
          ),

        _buildKitchenStatus(order.status),
      ],
    );
  }

  Widget _buildKitchenStatus(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.blue;
        label = "SELESAI DIMASAK";
        icon = Icons.restaurant_menu;
        break;
      case 'cooking':
        color = Colors.amber[700]!;
        label = "SEDANG DIMASAK";
        icon = Icons.soup_kitchen;
        break;
      case 'cancelled':
        color = Colors.red;
        label = "DIBATALKAN";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = "MENUNGGU DAPUR";
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}