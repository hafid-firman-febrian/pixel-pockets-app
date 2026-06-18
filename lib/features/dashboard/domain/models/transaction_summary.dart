/// Aggregated totals for the dashboard. Pure domain — no JSON.
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  double get spentPercentage {
    if (totalIncome <= 0) return 0;
    return totalExpense / totalIncome;
  }

  String get spentPercentageString =>
      '${(spentPercentage * 100).toStringAsFixed(0)}%';
}
