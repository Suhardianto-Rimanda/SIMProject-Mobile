class Recipe {
  final int recipeId;
  final int ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;

  Recipe({
    required this.recipeId,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      recipeId: json['recipe_id'],
      ingredientId: json['ingredient_id'],
      ingredientName: json['ingredient_name'],
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'],
    );
  }
}