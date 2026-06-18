import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Wire representation of a category. Owns JSON parsing so the domain model
/// stays pure.
class CategoryDto {
  final int id;
  final String name;
  final String? color;
  final String type;

  const CategoryDto({
    required this.id,
    required this.name,
    this.color,
    required this.type,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
        id: json['id'] as int,
        name: json['name'] as String,
        color: json['color'] as String?,
        type: json['type'] as String,
      );

  CategoryModel toDomain() =>
      CategoryModel(id: id, name: name, color: color, type: type);
}
