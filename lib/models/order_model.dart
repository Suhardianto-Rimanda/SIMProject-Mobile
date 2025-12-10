class OrderModel {
  final int id;
  final String invoiceNo;
  final String customerName;
  final double totalAmount;
  final String paymentMethod; // 'cash', 'qris', 'transfer', 'pending'
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime transactionDate;

  OrderModel({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.transactionDate,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0, // Fallback jika null
      invoiceNo: json['invoice'] ?? '-',
      customerName: json['customer'] ?? 'Umum',
      totalAmount: (json['total'] as num).toDouble(),
      paymentMethod: json['payment'] ?? 'pending',
      status: json['status'] ?? 'pending',
      // Parsing tanggal, fallback ke now jika error
      transactionDate: json['time'] != null
          ? DateTime.tryParse(json['time'].toString().replaceAll('/', '-')) ?? DateTime.now() // Handle format dd/MM vs yyyy-MM
          : DateTime.now(),
    );
  }

  // Helper untuk cek apakah belum dibayar
  bool get isUnpaid => paymentMethod == 'pending' || status == 'pending';
}