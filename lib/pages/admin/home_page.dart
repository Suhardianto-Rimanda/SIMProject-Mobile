import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../../models/admin_dashboard_model.dart';
import 'user_management_page.dart';
import 'production/production_menu_page.dart';
import 'finance_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _selectedIndex = 0;
  String _userFullName = 'Admin';


  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userFullName = prefs.getString('full_name') ?? prefs.getString('username') ?? 'Admin';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'UMKM KULINER' : _getAppBarTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
            tooltip: "Logout",
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminDashboardTab(fullName: _userFullName),
          const UserManagementPage(),
          const ProductionMenuPage(),
          const FinancePage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_rounded),
            label: 'Production',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on_rounded),
            label: 'Finance',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        elevation: 10,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 1: return 'Kelola Staff';
      case 2: return 'Produksi';
      case 3: return 'Keuangan';
      default: return 'Admin';
    }
  }
}

// --- TAB 1: DASHBOARD CONTENT ---
class AdminDashboardTab extends StatefulWidget {
  final String fullName;
  const AdminDashboardTab({super.key, this.fullName = 'Admin'});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AdminProvider>(context, listen: false).fetchDashboard()
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = Provider.of<AdminProvider>(context);
    final data = adminProv.dashboardData;
    final isLoading = adminProv.isLoadingDashboard;
    final error = adminProv.errorMessage;

    return RefreshIndicator(
      onRefresh: () => adminProv.fetchDashboard(),
      color: Colors.redAccent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildGreetingCard(),

          const SizedBox(height: 24),

          if (isLoading)
            const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
          else if (error != null)
            SizedBox(height: 200, child: Center(child: Text("Gagal memuat data: $error")))
          else if (data == null)
              const SizedBox(height: 200, child: Center(child: Text("Data kosong")))
            else ...[
                _buildSummaryGrid(data.summary),

                const SizedBox(height: 24),

                const Text("Tren Penjualan (7 Hari)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 12),
                Container(
                  height: 300,
                  padding: const EdgeInsets.only(right: 16, left: 0, top: 24, bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: _buildLineChart(data.chart),
                ),
              ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), shape: BoxShape.circle),
                child: const CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  child: Icon(Icons.person, color: Colors.redAccent, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Halo, Selamat Datang!",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      widget.fullName,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.notifications_none, color: Colors.white),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardSummary summary) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // FIX: Ubah dari 1.4 ke 1.2 agar kartu lebih tinggi (menghindari bottom overflow)
      childAspectRatio: 1.2,
      children: [
        _summaryCard("Omset Hari Ini", currency.format(summary.revenueToday), Colors.blueAccent, Icons.account_balance_wallet),
        _summaryCard("Total Transaksi", "${summary.trxToday}", Colors.green, Icons.receipt_long),
        _summaryCard("Sisa Stok", "${summary.lowStock} Item", Colors.orange, Icons.warning_amber_rounded),
        _summaryCard("Total Staff", "${summary.staffActive} Org", Colors.purpleAccent, Icons.group),
      ],
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          // FIX: Gunakan Expanded dan FittedBox agar teks tidak overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(DashboardChart chartData) {
    if (chartData.series.isEmpty) return const Center(child: Text("Belum ada data grafik"));

    List<FlSpot> spots = [];
    double? minY;
    double? maxY;

    for (int i = 0; i < chartData.series.length; i++) {
      double val = chartData.series[i];
      spots.add(FlSpot(i.toDouble(), val));

      if (minY == null || val < minY) minY = val;
      if (maxY == null || val > maxY) maxY = val;
    }

    double interval = ((maxY ?? 0) - (minY ?? 0));
    if (interval == 0) interval = (maxY ?? 0) == 0 ? 10 : (maxY ?? 0);

    double finalMinY = (minY ?? 0) - (interval * 0.2);
    double finalMaxY = (maxY ?? 0) + (interval * 0.2);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < chartData.labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      chartData.labels[index],
                      style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                    ),
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
                return Text(
                  NumberFormat.compact().format(value),
                  style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: finalMinY,
        maxY: finalMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.redAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.redAccent.withOpacity(0.2), Colors.redAccent.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.grey[400], fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}