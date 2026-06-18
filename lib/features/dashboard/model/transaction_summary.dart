class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  double get spentPercentage {
    if (totalIncome <= 0) return 0;
    return (totalExpense / totalIncome);
  }

  String get spentPercentageString =>
      '${(spentPercentage * 100).toStringAsFixed(0)}%';

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: json['total_income'],
      totalExpense: json['total_expense'],
      balance: json['balance'],
      transactionCount: json['transaction_count'],
    );
  }
}
