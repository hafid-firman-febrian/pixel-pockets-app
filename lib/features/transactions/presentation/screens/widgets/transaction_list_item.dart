import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// A single transaction row: a category-colored accent bar, the note/category
/// title with the category label beneath, and the signed amount + date.
class TransactionListItem extends StatelessWidget {
  const TransactionListItem({super.key, required this.transaction, this.onTap});

  final TransactionModel transaction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.fromHex(transaction.categoryColor);
    final isIncome = transaction.isIncome;

    final hasDescription = transaction.description?.isNotEmpty ?? false;
    final title = hasDescription
        ? transaction.description!
        : (transaction.categoryName ?? 'Uncategorized');
    // Only show the category label as a second line when the title is the note.
    final categoryLabel = hasDescription ? transaction.categoryName : null;

    final amountText =
        '${isIncome ? '+' : '-'}${_thousands(transaction.amount)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s12,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyNormal.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (categoryLabel != null) ...[
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        categoryLabel.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.overlineSm.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: AppTextStyles.bodyNormal.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isIncome ? AppColors.income : AppColors.expense,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(
                    _formatDate(transaction.transactionDate),
                    style: AppTextStyles.overlineSm.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thousands-separated amount without the "Rp" prefix (e.g. `8.000.000`).
  String _thousands(double amount) {
    final formatted = CurrencyFormatter.input(amount);
    return formatted.isEmpty ? '0' : formatted;
  }

  /// `yyyy-MM-dd` → `17 JUN`; falls back to the raw string if unparseable.
  String _formatDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('d MMM').format(parsed).toUpperCase();
  }
}
