class Ingredient {
  final int id;
  final String name;
  final String unit;          // Satuan Resep (misal: ml, gr)
  final String purchaseUnit;  // Satuan Beli (misal: Botol, Karung)
  final double conversionRate;// 1 Satuan Beli = brp Satuan Resep
  final double stock;         // Stok saat ini (dalam Satuan Resep)

  Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.purchaseUnit,
    required this.conversionRate,
    required this.stock,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'],
      name: json['name'],
      unit: json['unit'],
      // Handle nilai null dari backend dengan default value
      purchaseUnit: json['purchase_unit'] ?? json['unit'],
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 1.0,
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}