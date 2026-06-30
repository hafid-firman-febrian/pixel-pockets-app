class TransactionFilter {
  final int? salaryPeriodId;
  final String? filter;
  final String? startDate;
  final String? endDate;
  final String? transactionType;
  final int? categoryId;
  final int page;
  final int limit;

  const TransactionFilter({
    this.salaryPeriodId,
    this.filter,
    this.startDate,
    this.endDate,
    this.transactionType,
    this.categoryId,
    this.page = 1,
    this.limit = 20,
  });

  TransactionFilter copyWith({
    int? salaryPeriodId,
    bool clearSalaryPeriodId = false,
    String? filter,
    bool clearFilter = false,
    String? startDate,
    String? endDate,
    String? transactionType,
    bool clearTransactionType = false,
    int? categoryId,
    bool clearCategoryId = false,
    int? page,
    int? limit,
  }) {
    return TransactionFilter(
      salaryPeriodId: clearSalaryPeriodId
          ? null
          : (salaryPeriodId ?? this.salaryPeriodId),
      filter: clearFilter ? null : (filter ?? this.filter),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.salaryPeriodId == salaryPeriodId &&
      other.filter == filter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.transactionType == transactionType &&
      other.categoryId == categoryId &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
    salaryPeriodId,
    filter,
    startDate,
    endDate,
    transactionType,
    categoryId,
    page,
    limit,
  );
}
