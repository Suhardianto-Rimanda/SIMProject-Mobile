import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
// Import PDF & Printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../../providers/admin_provider.dart';
import '../../../models/finance_model.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late DateTime _startDate;
  late DateTime _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final _expenseNameCtrl = TextEditingController();
  final _expenseAmountCtrl = TextEditingController();
  DateTime _expenseDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
    _loadData();
  }

  void _loadData() {
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchFinanceData(
          startDate: _dateFormat.format(_startDate),
          endDate: _dateFormat.format(_endDate),
        )
    );
  }

  // --- FUNGSI CETAK PDF ---
  Future<void> _printReport(ProfitLossModel? profitLoss, SalesReportModel? salesReport) async {
    if (profitLoss == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data belum dimuat")));
      return;
    }

    final pdf = pw.Document();
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final titleFont = await PdfGoogleFonts.poppinsBold();
    final regularFont = await PdfGoogleFonts.poppinsRegular();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("UMKM KULINER", style: pw.TextStyle(font: titleFont, fontSize: 24, color: PdfColors.redAccent)),
                    pw.Text("E-STATEMENT", style: pw.TextStyle(font: titleFont, fontSize: 18, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // PERIODE
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(4)),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Periode Laporan:", style: pw.TextStyle(font: regularFont)),
                    pw.Text(
                      "${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}",
                      style: pw.TextStyle(font: titleFont),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // RINGKASAN KEUANGAN (Profit & Loss)
              pw.Text("Ringkasan Laba Rugi", style: pw.TextStyle(font: titleFont, fontSize: 16)),
              pw.Divider(),
              _buildPdfRow("Total Omset (Pendapatan)", profitLoss.revenue, currency, titleFont, regularFont, isPositive: true),
              _buildPdfRow("Total HPP (Modal Bahan)", -profitLoss.cogs, currency, titleFont, regularFont, isNegative: true),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildPdfRow("Laba Kotor (Gross Profit)", profitLoss.grossProfit, currency, titleFont, regularFont),
              pw.SizedBox(height: 10),
              _buildPdfRow("Biaya Operasional", -profitLoss.operationalExpense, currency, titleFont, regularFont, isNegative: true),
              pw.Divider(thickness: 2),
              _buildPdfRow("LABA BERSIH (NET PROFIT)", profitLoss.netProfit, currency, titleFont, regularFont, isBold: true, color: PdfColors.green900),

              pw.SizedBox(height: 40),

              // TABEL TRANSAKSI HARIAN
              pw.Text("Rincian Penjualan Harian", style: pw.TextStyle(font: titleFont, fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                border: null,
                headerStyle: pw.TextStyle(font: titleFont, fontSize: 10, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.redAccent),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellStyle: pw.TextStyle(font: regularFont, fontSize: 10),
                cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
                headers: ['Tanggal', 'Omset'],
                data: salesReport?.dailyData.map((data) => [
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(data.date)),
                  currency.format(data.revenue),
                ]).toList() ?? [],
              ),

              pw.Spacer(),
              pw.Text(
                "Laporan ini dibuat secara otomatis oleh sistem UMKM KULINER pada ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}",
                style: pw.TextStyle(font: regularFont, fontSize: 8, color: PdfColors.grey500),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Keuangan_${DateFormat('yyyyMMdd').format(_startDate)}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, double value, NumberFormat currency, pw.Font bold, pw.Font regular, {bool isBold = false, PdfColor? color, bool isNegative = false, bool isPositive = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: isBold ? bold : regular, fontSize: 12)),
          pw.Text(
            currency.format(value),
            style: pw.TextStyle(
              font: isBold ? bold : regular,
              fontSize: isBold ? 14 : 12,
              color: isNegative ? PdfColors.red : (isPositive ? PdfColors.blue : (color ?? PdfColors.black)),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Kode _selectDateRange, _showAddExpenseDialog tetap SAMA) ...
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  void _showAddExpenseDialog() {
    _expenseNameCtrl.clear();
    _expenseAmountCtrl.clear();
    _expenseDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(children: [Icon(Icons.money_off, color: Colors.red), SizedBox(width: 8), Text("Input Biaya")]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Catat pengeluaran (Listrik, Gaji, dll)", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _expenseNameCtrl,
                      decoration: const InputDecoration(labelText: "Nama Biaya", border: OutlineInputBorder(), hintText: "Contoh: Token Listrik"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _expenseAmountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Jumlah (Rp)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text("Tanggal:", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(context: context, initialDate: _expenseDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                        if (picked != null) {
                          setDialogState(() => _expenseDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_dateFormat.format(_expenseDate)),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (_expenseNameCtrl.text.isEmpty || _expenseAmountCtrl.text.isEmpty) return;
                    try {
                      await Provider.of<AdminProvider>(context, listen: false).addExpense(
                        _expenseNameCtrl.text,
                        double.parse(_expenseAmountCtrl.text),
                        _dateFormat.format(_expenseDate),
                      );
                      if (mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Biaya berhasil disimpan")));
                      _loadData();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: $e")));
                    }
                  },
                  child: const Text("Simpan"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Laporan Keuangan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // TOMBOL CETAK PDF
          IconButton(
            icon: const Icon(Icons.print, color: Colors.blue),
            tooltip: "Cetak e-Statement",
            onPressed: () => _printReport(prov.profitLoss, prov.salesReport),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Input Biaya", style: TextStyle(color: Colors.white)),
      ),
      body: prov.isLoadingFinance
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- FILTER TANGGAL ---
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${DateFormat('dd MMM yyyy').format(_startDate)}  s/d  ${DateFormat('dd MMM yyyy').format(_endDate)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(onPressed: () => _selectDateRange(context), child: const Text("Ganti Tanggal"))
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- BAGIAN 1: KARTU RINGKASAN (GRID) ---
              if (prov.profitLoss != null)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildFinanceCard("LABA BERSIH", currency.format(prov.profitLoss!.netProfit), Colors.green),
                    _buildFinanceCard("TOTAL OMSET", currency.format(prov.profitLoss!.revenue), Colors.blue),
                    _buildFinanceCard("TOTAL HPP", currency.format(prov.profitLoss!.cogs), Colors.redAccent),
                    _buildFinanceCard("ASET GUDANG", currency.format(prov.totalAssetValue), Colors.lightBlue),
                  ],
                ),

              const SizedBox(height: 24),

              // --- BAGIAN 2: GRAFIK PENJUALAN ---
              const Text("Tren Penjualan Harian", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                height: 300,
                padding: const EdgeInsets.only(right: 16, top: 24, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                ),
                child: _buildSalesChart(prov.salesReport),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(SalesReportModel? report) {
    if (report == null || report.dailyData.isEmpty) {
      return const Center(child: Text("Tidak ada data penjualan pada periode ini"));
    }

    List<FlSpot> spots = [];
    List<String> xLabels = [];

    for (int i = 0; i < report.dailyData.length; i++) {
      spots.add(FlSpot(i.toDouble(), report.dailyData[i].revenue));
      try {
        final date = DateTime.parse(report.dailyData[i].date);
        xLabels.add(DateFormat('dd/MM').format(date));
      } catch (e) {
        xLabels.add(report.dailyData[i].date);
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey[200]!, strokeWidth: 1)),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < xLabels.length) {
                  if (xLabels.length > 7 && index % 2 != 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(xLabels[index], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(NumberFormat.compact().format(value), style: const TextStyle(fontSize: 10, color: Colors.grey));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.1)),
          ),
        ],
        minY: 0,
      ),
    );
  }
}