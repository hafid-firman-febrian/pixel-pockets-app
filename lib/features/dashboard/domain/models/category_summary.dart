
class CategorySummary {
  final int categoryId;
  final String name;
  final String? colorHex; 
  final String type; 
  final double total;
  final double percentage; 
  final int count;

  const CategorySummary({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.type,
    required this.total,
    required this.percentage,
    required this.count,
  });
}
