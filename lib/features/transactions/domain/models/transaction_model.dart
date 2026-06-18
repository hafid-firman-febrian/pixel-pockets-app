/// A single transaction — pure domain entity. No JSON, no Dio.
class TransactionModel {
  final int id;
  final String transactionDate;
  final String transactionType; // "income" | "expense"
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor; // hex "#RRGGBB"
  final String? createdAt;
  final String? updatedAt;

  const TransactionModel({
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

  bool get isIncome => transactionType == 'income';
  bool get isExpense => transactionType == 'expense';
}
