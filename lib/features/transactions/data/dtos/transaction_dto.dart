import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Wire representation of a transaction. Owns all JSON so the domain model
/// stays pure. The API returns camelCase but accepts snake_case on write.
class TransactionDto {
  final int id;
  final String transactionDate;
  final String transactionType;
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor;
  final String? createdAt;
  final String? updatedAt;

  const TransactionDto({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    required this.amount,
    this.categoryId,
    this.description,
    this.categoryName,
    this.categoryColor,
    this.createdAt,
    this.updatedAt,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
        id: json['id'] as int,
        transactionDate: json['transactionDate'] as String,
        transactionType: json['transactionType'] as String,
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as int?,
        description: json['description'] as String?,
        categoryName: json['categoryName'] as String?,
        categoryColor: json['categoryColor'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  factory TransactionDto.fromDomain(TransactionModel m) => TransactionDto(
        id: m.id,
        transactionDate: m.transactionDate,
        transactionType: m.transactionType,
        amount: m.amount,
        categoryId: m.categoryId,
        description: m.description,
        categoryName: m.categoryName,
        categoryColor: m.categoryColor,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  /// Write payload (snake_case). Only fields the API accepts on write.
  Map<String, dynamic> toJson() => {
        'transaction_date': transactionDate,
        'transaction_type': transactionType,
        'amount': amount,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
      };

  TransactionModel toDomain() => TransactionModel(
        id: id,
        transactionDate: transactionDate,
        transactionType: transactionType,
        amount: amount,
        categoryId: categoryId,
        description: description,
        categoryName: categoryName,
        categoryColor: categoryColor,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
