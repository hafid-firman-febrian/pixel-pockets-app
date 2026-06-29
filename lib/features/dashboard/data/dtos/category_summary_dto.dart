import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';

/// Wire representation of one row from `GET /api/summary/by-category`.
class CategorySummaryDto {
  final int categoryId;
  final String name;
  final String? color;
  final String type;
  final double total;
  final double percentage;
  final int count;

  const CategorySummaryDto({
    required this.categoryId,
    required this.name,
    required this.color,
    required this.type,
    required this.total,
    required this.percentage,
    required this.count,
  });

  factory CategorySummaryDto.fromJson(Map<String, dynamic> json) =>
      CategorySummaryDto(
        categoryId: json['category_id'] as int,
        name: json['category_name'] as String,
        color: json['category_color'] as String?,
        type: json['transaction_type'] as String,
        total: (json['total'] as num).toDouble(),
        percentage: (json['percentage'] as num).toDouble(),
        count: json['count'] as int,
      );

  CategorySummary toDomain() => CategorySummary(
        categoryId: categoryId,
        name: name,
        colorHex: color,
        type: type,
        total: total,
        percentage: percentage,
        count: count,
      );
}
