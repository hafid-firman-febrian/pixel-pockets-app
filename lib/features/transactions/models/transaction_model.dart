/// A single transaction. Mirrors the `/api/transactions` response shape.
///
/// Note the asymmetry: the API returns camelCase keys (`transactionDate`)
/// but expects snake_case keys on write (`transaction_date`) — [toJson]
/// only emits the writable fields.
class TransactionModel {
  final int id;
  final String transactionDate;
  final String transactionType; // "income" | "expense"
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor;
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
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
  }

  /// Body for POST/PUT. Only the fields the API accepts on write.
  Map<String, dynamic> toJson() {
    return {
      'transaction_date': transactionDate,
      'transaction_type': transactionType,
      'amount': amount,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
    };
  }
}
