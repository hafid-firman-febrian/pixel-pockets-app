/// A spending/income category — pure domain entity. No JSON.
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
}
