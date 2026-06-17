import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../models/transaction_model.dart';

/// One row in the transaction list. Pure presentation — all data comes in
/// via [transaction]; taps/dismiss are delegated to the parent.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(transaction.categoryColor);
    final isIncome = transaction.isIncome;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(
          isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.categoryName ?? 'Tanpa Kategori',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          transaction.transactionDate,
          if (transaction.description != null &&
              transaction.description!.isNotEmpty)
            transaction.description,
        ].join(' • '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
      ),
      trailing: Text(
        CurrencyFormatter.formatSigned(transaction.amount, isIncome: isIncome),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
      ),
    );
  }
}
