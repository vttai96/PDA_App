// Class này dùng để hứng toàn bộ JSON từ API
class RecipeResponse {
  final String status;
  final List<IngredientModel> ingredients;

  RecipeResponse({required this.status, required this.ingredients});

  factory RecipeResponse.fromJson(Map<String, dynamic> json) {
    return RecipeResponse(
      status: json['status']?.toString() ?? '',
      // Duyệt mảng 'ingredients' từ JSON và biến thành danh sách IngredientModel
      ingredients: (json['ingredients'] as List? ?? [])
          .map((item) => IngredientModel.fromJson(item))
          .toList(),
    );
  }
}

// Class này dùng cho từng nguyên liệu (Giữ nguyên class cũ nhưng sửa factory)
class IngredientModel {
  final String ingredientCode;
  final String ingredientName;
  final double quantity;
  final String unitOfMeasurement;

  IngredientModel({
    required this.ingredientCode,
    required this.ingredientName,
    required this.quantity,
    required this.unitOfMeasurement,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      ingredientCode: json['IngredientCode']?.toString() ?? '',
      ingredientName: json['IngredientName']?.toString() ?? '',
      quantity: (json['Quantity'] as num? ?? 0).toDouble(),
      unitOfMeasurement: json['UnitOfMeasurement']?.toString() ?? '',
    );
  }
}
