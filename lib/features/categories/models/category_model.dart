/// A spending/income category. Mirrors the `/api/categories` response.
class CategoryModel {
  final int id;
  final String name;
  final String? color;
  final String type; // "income" | "expense"

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    required this.type,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String?,
      type: json['type'] as String,
    );
  }
}
