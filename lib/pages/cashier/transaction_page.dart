import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// PDF & Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // Namespace 'pw'
import 'package:printing/printing.dart';

import '../../providers/sales_provider.dart';
import '../../models/product_model.dart';
import '../../models/cart_item_model.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _selectedCategory = 'All';
  final Map<String, String> _categories = {
    'All': 'Semua',
    'Food': 'Makanan',
    'Drink': 'Minuman',
    'Snack': 'Camilan',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<SalesProvider>(context, listen: false).fetchMenu()
    );
  }

  // --- LOGIKA CETAK PDF STRUK ---
  Future<void> _printReceipt({
    required String invoice,
    required String customer,
    required String cashier,
    required List<CartItem> items,
    required double total,
    required double pay,
    required double change,
    required String method,
  }) async {
    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();

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
              pw.Text("UMKM KULINER", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text("Jl. Bathin Alam No. 1", style: const pw.TextStyle(fontSize: 10)),
              pw.Text(DateFormat('dd-MM-yyyy HH:mm').format(now), style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // PERBAIKAN: Gunakan pw.MainAxisAlignment
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
                      pw.Text(item.product.name, style: const pw.TextStyle(fontSize: 10)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // FIX
                        children: [
                          pw.Text("${item.quantity} x ${currency.format(item.product.price)}", style: const pw.TextStyle(fontSize: 10)),
                          pw.Text(currency.format(item.totalPrice), style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                    ]
                );
              }),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totals Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // FIX
                children: [
                  pw.Text("TOTAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(currency.format(total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // FIX
                children: [
                  pw.Text("Bayar", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(currency.format(pay), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // FIX
                children: [
                  pw.Text("Kembali", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(currency.format(change), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // FIX
                children: [
                  pw.Text("Metode", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(method.toUpperCase(), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),

              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              pw.Text("Terima Kasih!", style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
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

  // --- DIALOG STRUK SUKSES ---
  void _showReceiptDialog({
    required String invoice,
    required double change,
    required double total,
    required double pay,
    required String method,
    required String customer,
    required List<CartItem> itemsSnapshot,
  }) async {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final prefs = await SharedPreferences.getInstance();
    final cashierName = prefs.getString('username') ?? 'Kasir';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 50),
            ),
            const SizedBox(height: 16),
            const Text("Pembayaran Berhasil!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8)
              ),
              child: Column(
                children: [
                  _rowInfo("Invoice", invoice),
                  _rowInfo("Total", currency.format(total), isBold: true),
                  if (method == 'cash') _rowInfo("Kembali", currency.format(change), color: Colors.green),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Tutup"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _printReceipt(
                          invoice: invoice,
                          customer: customer,
                          cashier: cashierName,
                          items: itemsSnapshot,
                          total: total,
                          pay: pay,
                          change: change,
                          method: method
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text("Cetak"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _rowInfo(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87
          )),
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    final salesProv = Provider.of<SalesProvider>(context, listen: false);
    final customerNameCtrl = TextEditingController(text: "Pelanggan Umum");
    final amountReceivedCtrl = TextEditingController();

    String paymentMethod = 'cash';
    double change = 0.0;
    double receivedAmount = 0.0;

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20, right: 20, top: 20
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
                      ),
                    ),
                    const Text("Konfirmasi Pesanan", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3))
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Tagihan", style: TextStyle(color: Colors.black87, fontSize: 16)),
                          Text(
                              currency.format(salesProv.totalTransactionAmount),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: customerNameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Nama Pelanggan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _paymentOption("Tunai", "cash", paymentMethod, (val) => setSheetState(() => paymentMethod = val)),
                        const SizedBox(width: 10),
                        _paymentOption("QRIS", "qris", paymentMethod, (val) => setSheetState(() => paymentMethod = val)),
                        const SizedBox(width: 10),
                        _paymentOption("Transfer", "transfer", paymentMethod, (val) => setSheetState(() => paymentMethod = val)),
                      ],
                    ),

                    if (paymentMethod == 'cash') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: amountReceivedCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Uang Diterima (Rp)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                        onChanged: (val) {
                          setSheetState(() {
                            receivedAmount = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                            change = receivedAmount - salesProv.totalTransactionAmount;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: change >= 0 ? Colors.green[50] : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: change >= 0 ? Colors.green : Colors.red)
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              change >= 0 ? "Kembalian:" : "Kurang Bayar:",
                              style: TextStyle(
                                  color: change >= 0 ? Colors.green[800] : Colors.red[800],
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              currency.format(change.abs()),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: change >= 0 ? Colors.green[800] : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (paymentMethod == 'cash' && change < 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Uang yang diterima kurang!"), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          if (paymentMethod != 'cash') {
                            receivedAmount = salesProv.totalTransactionAmount;
                            change = 0;
                          }

                          final cartSnapshot = List<CartItem>.from(salesProv.cart);
                          final totalSnapshot = salesProv.totalTransactionAmount;
                          final customerSnapshot = customerNameCtrl.text;
                          final methodSnapshot = paymentMethod;
                          final paySnapshot = receivedAmount;
                          final changeSnapshot = change;

                          try {
                            final invoiceNo = await salesProv.processTransaction(
                              customerName: customerNameCtrl.text,
                              paymentMethod: paymentMethod,
                            );

                            if (mounted) {
                              Navigator.pop(ctx);
                              _showReceiptDialog(
                                  invoice: invoiceNo,
                                  customer: customerSnapshot,
                                  itemsSnapshot: cartSnapshot,
                                  total: totalSnapshot,
                                  pay: paySnapshot,
                                  change: changeSnapshot,
                                  method: methodSnapshot
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                          }
                        },
                        child: const Text("Bayar & Cetak Struk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
      ),
    );
  }

  Widget _paymentOption(String label, String value, String groupValue, Function(String) onTap) {
    final isSelected = value == groupValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
            border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProv = Provider.of<SalesProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final List<Product> filteredProducts = _selectedCategory == 'All'
        ? salesProv.menuList
        : salesProv.menuList.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((entry) {
                  return _buildCategoryChip(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: salesProv.isLoading && salesProv.menuList.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredProducts.isEmpty
                ? Center(child: Text("Tidak ada produk kategori ini", style: TextStyle(color: Colors.grey[500])))
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (ctx, i) {
                final product = filteredProducts[i];
                final cartItem = salesProv.cart.firstWhere(
                        (c) => c.product.id == product.id,
                    orElse: () => CartItem(product: product, quantity: 0)
                );

                return _buildProductCard(product, cartItem.quantity, salesProv);
              },
            ),
          ),
        ],
      ),

      bottomSheet: salesProv.cart.isNotEmpty
          ? Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${salesProv.totalItems} Item Dipilih", style: const TextStyle(color: Colors.grey)),
                Text(
                  currency.format(salesProv.totalTransactionAmount),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showCheckoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: const Icon(Icons.payment),
              label: const Text("Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      )
          : null,
    );
  }

  Widget _buildProductCard(Product product, int qty, SalesProvider prov) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: product.category == 'Food' ? Colors.orange[50] : (product.category == 'Drink' ? Colors.blue[50] : Colors.purple[50]),
              width: double.infinity,
              child: Icon(
                product.category == 'Food' ? Icons.restaurant :
                (product.category == 'Drink' ? Icons.local_drink : Icons.fastfood),
                size: 48,
                color: product.category == 'Food' ? Colors.orange[300] : (product.category == 'Drink' ? Colors.blue[300] : Colors.purple[300]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(currency.format(product.price), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                qty == 0
                    ? SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () => prov.addToCart(product),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blueAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      foregroundColor: Colors.blueAccent,
                    ),
                    child: const Text("Tambah"),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _circleBtn(Icons.remove, Colors.red, () => prov.decreaseQty(product)),
                    Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _circleBtn(Icons.add, Colors.blue, () => prov.addToCart(product)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildCategoryChip(String backendValue, String label) {
    final isSelected = _selectedCategory == backendValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected && _selectedCategory != backendValue) {
            setState(() {
              _selectedCategory = backendValue;
            });
          }
        },
        selectedColor: Colors.blueAccent,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey[300]!)
        ),
        showCheckmark: false,
      ),
    );
  }
}