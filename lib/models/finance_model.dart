class ProfitLossModel {
  final double revenue;
  final double cogs;
  final double grossProfit;
  final double operationalExpense;
  final double netProfit;

  ProfitLossModel({
    required this.revenue,
    required this.cogs,
    required this.grossProfit,
    required this.operationalExpense,
    required this.netProfit,
  });

  factory ProfitLossModel.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return ProfitLossModel(
      revenue: (details['1. Pendapatan (Omzet)'] as num).toDouble(),
      cogs: (details['2. Beban Pokok Penjualan (HPP Bahan)'] as num).toDouble(),
      grossProfit: (details['3. Laba Kotor (Gross Profit)'] as num).toDouble(),
      operationalExpense: (details['4. Beban Operasional'] as num).toDouble(),
      netProfit: (details['5. LABA BERSIH (Net Profit)'] as num).toDouble(),
    );
  }
}

class SalesReportModel {
  final double grandTotal;
  final List<DailySales> dailyData;

  SalesReportModel({required this.grandTotal, required this.dailyData});

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    var list = json['daily_data'] as List;
    List<DailySales> dataList = list.map((i) => DailySales.fromJson(i)).toList();
    return SalesReportModel(
      grandTotal: (json['grand_total_revenue'] as num).toDouble(),
      dailyData: dataList,
    );
  }
}

class DailySales {
  final String date;
  final double revenue;

  DailySales({required this.date, required this.revenue});

  factory DailySales.fromJson(Map<String, dynamic> json) {
    return DailySales(
      date: json['date'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }
}