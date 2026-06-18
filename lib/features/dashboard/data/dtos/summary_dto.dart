import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Wire representation of the summary endpoint (`GET /api/summary`).
class SummaryDto {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  const SummaryDto({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  factory SummaryDto.fromJson(Map<String, dynamic> json) => SummaryDto(
        totalIncome: (json['total_income'] as num).toDouble(),
        totalExpense: (json['total_expense'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        transactionCount: json['transaction_count'] as int,
      );

  TransactionSummary toDomain() => TransactionSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        transactionCount: transactionCount,
      );
}
