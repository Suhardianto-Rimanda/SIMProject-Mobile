class AdminDashboardModel {
  final DashboardSummary summary;
  final DashboardChart chart;

  AdminDashboardModel({required this.summary, required this.chart});

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      summary: DashboardSummary.fromJson(json['summary']),
      chart: DashboardChart.fromJson(json['chart']),
    );
  }
}

class DashboardSummary {
  final double revenueToday;
  final int trxToday;
  final int lowStock;
  final int staffActive;

  DashboardSummary({
    required this.revenueToday,
    required this.trxToday,
    required this.lowStock,
    required this.staffActive,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      // Backend mungkin kirim int atau float, handle keduanya
      revenueToday: (json['revenue_today'] as num).toDouble(),
      trxToday: json['trx_today'] as int,
      lowStock: json['low_stock'] as int,
      staffActive: json['staff_active'] as int,
    );
  }
}

class DashboardChart {
  final List<String> labels;
  final List<double> series;

  DashboardChart({required this.labels, required this.series});

  factory DashboardChart.fromJson(Map<String, dynamic> json) {
    return DashboardChart(
      labels: List<String>.from(json['labels']),
      series: List<dynamic>.from(json['series'])
          .map((e) => (e as num).toDouble())
          .toList(),
    );
  }
}