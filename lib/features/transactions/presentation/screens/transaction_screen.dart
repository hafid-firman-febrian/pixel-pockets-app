import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/core/widgets/pixel_card.dart';
import 'package:pixel_pocket/core/widgets/pixel_confirm_dialog.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_form_sheet.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_list_item.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_range_filter.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
import 'package:pixelarticons/pixel.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionScreen extends ConsumerWidget {
  const TransactionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsControllerProvider);

    ref.watch(categoriesProvider);

    return SafeArea(
      child: Scaffold(
        floatingActionButton: PixelButton(
          icon: Pixel.plus,
          size: PixelButtonSize.lg,
          onPressed: () => TransactionFormSheet.show(context),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.section),
            Padding(
              padding: AppSpacing.card,
              child: Text('TRANSACTIONS', style: AppTextStyles.displayMedium),
            ),
            const Padding(padding: AppSpacing.card, child: _SearchField()),

            const TransactionRangeFilter(),
            Expanded(
              child: transactionsAsync.isLoading
                  ? const _ListSkeleton()
                  : switch (transactionsAsync) {
                      AsyncValue(:final error?) => _ErrorView(
                        message: error is Failure
                            ? error.message
                            : error.toString(),
                        type: error is Failure
                            ? error.type
                            : FailureType.unknown,
                        onRetry: () =>
                            ref.invalidate(transactionsControllerProvider),
                      ),
                      AsyncValue(:final value?) => _buildList(
                        context,
                        ref,
                        value,
                      ),
                      _ => const _ListSkeleton(),
                    },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<TransactionModel> transactions,
  ) {
    if (transactions.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.refresh(transactionsControllerProvider.future),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(child: _EmptyView()),
            ),
          ),
        ),
      );
    }

    final notifier = ref.read(transactionsControllerProvider.notifier);
    final children = <Widget>[];

    final groups = <MapEntry<String, List<TransactionModel>>>[];
    for (final tx in transactions) {
      if (groups.isEmpty || groups.last.key != tx.transactionDate) {
        groups.add(MapEntry(tx.transactionDate, [tx]));
      } else {
        groups.last.value.add(tx);
      }
    }

    for (var g = 0; g < groups.length; g++) {
      if (g > 0) children.add(const SizedBox(height: AppSpacing.section));
      final group = groups[g];
      var income = 0.0;
      var expense = 0.0;
      for (final tx in group.value) {
        if (tx.isIncome) {
          income += tx.amount;
        } else {
          expense += tx.amount;
        }
      }
      children.add(
        _DateGroupCard(
          date: group.key,
          income: income,
          expense: expense,
          items: [
            for (var i = 0; i < group.value.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: AppColors.border),
              _dismissibleItem(context, ref, group.value[i]),
            ],
          ],
        ),
      );
    }

    if (notifier.hasMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 300) {
          notifier.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () => ref.refresh(transactionsControllerProvider.future),

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s8,
            AppSpacing.s8,
            AppSpacing.s8,
            96,
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _dismissibleItem(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) {
    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => _delete(context, ref, tx),
      child: TransactionListItem(
        transaction: tx,
        onTap: () => TransactionFormSheet.show(context, existing: tx),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      color: AppColors.expense,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.s24),
      child: const Icon(Pixel.trash, color: Colors.white),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) {
    return showPixelConfirm(
      context,
      title: 'Delete transaction?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmVariant: PixelButtonVariant.danger,
      icon: Pixel.trash,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionModel tx,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(transactionsControllerProvider.notifier)
        .delete(tx.id);
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
      return;
    }

    final error = ref.read(transactionsControllerProvider).error;
    final message = error is Failure ? error.message : 'Failed to delete';
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.expense),
    );
    ref.invalidate(transactionsControllerProvider);
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  static const _debounce = Duration(milliseconds: 300);

  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(transactionSearchProvider);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(_debounce, () {
      ref.read(transactionSearchProvider.notifier).state = value.trim();
    });
    setState(() {});
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    ref.read(transactionSearchProvider.notifier).state = '';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodyNormal,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s8,
        ),
        hintText: 'Search description or category',
        hintStyle: AppTextStyles.bodyNormal.copyWith(
          color: AppColors.textMuted,
        ),
        prefixIcon: const Icon(
          Pixel.search,
          size: 16,
          color: AppColors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        suffixIcon: _controller.text.isEmpty
            ? null
            : InkWell(
                onTap: _clear,
                child: const Icon(
                  Pixel.close,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
        suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _DateGroupCard extends StatelessWidget {
  const _DateGroupCard({
    required this.date,
    required this.items,
    this.income = 0,
    this.expense = 0,
  });

  final String date;
  final List<Widget> items;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    return PixelCard(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s8,
            ),
            child: _DateGroupHeader(
              date: date,
              income: income,
              expense: expense,
            ),
          ),

          PixelCard(child: Column(children: items)),
        ],
      ),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  const _DateGroupHeader({
    required this.date,
    this.income = 0,
    this.expense = 0,
  });

  final String date;
  final double income;
  final double expense;

  String get _label {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date.toUpperCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final pretty = DateFormat('d MMM yyyy').format(day).toUpperCase();
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'TODAY — $pretty';
    if (diff == 1) return 'YESTERDAY — $pretty';
    return pretty;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _label,
            style: AppTextStyles.overlineLg.copyWith(color: AppColors.primary),
          ),
        ),
        if (income > 0) ...[
          const SizedBox(width: AppSpacing.s8),
          Text(
            '+${CurrencyFormatter.format(income)}',
            style: AppTextStyles.overlineSm.copyWith(
              color: AppColors.income,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (expense > 0) ...[
          const SizedBox(width: AppSpacing.s8),
          Text(
            '-${CurrencyFormatter.format(expense)}',
            style: AppTextStyles.overlineSm.copyWith(
              color: AppColors.expense,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    const placeholder = TransactionModel(
      id: 0,
      transactionDate: '2026-06-17',
      transactionType: 'expense',
      amount: 50000,
      categoryName: 'Category',
      description: 'Placeholder note',
    );

    return Skeletonizer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s8,
          AppSpacing.s8,
          AppSpacing.s8,
          96,
        ),
        children: [
          for (var g = 0; g < 2; g++) ...[
            if (g > 0) const SizedBox(height: AppSpacing.section),
            _DateGroupCard(
              date: '2026-06-17',
              items: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  const TransactionListItem(transaction: placeholder),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Pixel.reciept, size: 64, color: AppColors.textMuted),
        SizedBox(height: AppSpacing.section),
        Text(
          'No transactions in this range',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.type,
    required this.onRetry,
  });

  final String message;
  final FailureType type;
  final VoidCallback onRetry;

  IconData get _icon {
    switch (type) {
      case FailureType.noConnection:
        return Pixel.downasaur;
      case FailureType.timeout:
        return Pixel.hourglass;
      case FailureType.server:
        return Pixel.server;
      case FailureType.notFound:
      case FailureType.unauthorized:
      case FailureType.cancelled:
      case FailureType.unknown:
        return Pixel.cellularsignaloff;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.s12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.section),
            PixelButton(
              onPressed: onRetry,
              icon: Pixel.reload,
              label: 'Try Again',
            ),
          ],
        ),
      ),
    );
  }
}
