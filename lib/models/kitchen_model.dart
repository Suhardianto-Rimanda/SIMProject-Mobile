class KitchenStockItem {
  final int id;
  final String name;
  final double stock;
  final String unit;
  final String status; // Aman, Menipis, Habis
  final String purchaseUnit;
  final double conversionRate;

  KitchenStockItem({
    required this.id,
    required this.name,
    required this.stock,
    required this.unit,
    required this.status,
    required this.purchaseUnit,
    required this.conversionRate,
  });

  factory KitchenStockItem.fromJson(Map<String, dynamic> json) {
    return KitchenStockItem(
      id: json['id'],
      name: json['name'],
      stock: (json['stock'] as num).toDouble(),
      unit: json['unit'],
      status: json['status'],
      purchaseUnit: json['purchase_unit'] ?? json['unit'],
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class KitchenQueueItem {
  final int id;
  final String invoice;
  final String status;
  final String customer;

  KitchenQueueItem({
    required this.id,
    required this.invoice,
    required this.status,
    required this.customer,
  });

  factory KitchenQueueItem.fromJson(Map<String, dynamic> json) {
    return KitchenQueueItem(
      id: json['id'],
      invoice: json['invoice'],
      status: json['status'],
      customer: json['customer'],
    );
  }
}

// Model untuk Grouping per Menu
class KitchenTaskGroup {
  final String menuName;
  final int totalQty;
  final List<KitchenQueueItem> orders;

  KitchenTaskGroup({
    required this.menuName,
    required this.totalQty,
    required this.orders,
  });
}