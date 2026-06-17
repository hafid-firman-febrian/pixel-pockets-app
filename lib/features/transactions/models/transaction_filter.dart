/// Immutable filter state for the transactions list.
///
/// Maps to the query params accepted by `/api/transactions`:
/// - [salaryPeriodId] has the highest priority on the server.
/// - [filter] is one of `week` | `month` | `year` | `custom`.
/// - [startDate] + [endDate] are required when `filter == custom`.
/// - [transactionType] is `income` | `expense` (null = both).
class TransactionFilter {
  final int? salaryPeriodId;
  final String? filter; // week | month | year | custom
  final String? startDate; // yyyy-MM-dd
  final String? endDate; // yyyy-MM-dd
  final String? transactionType; // income | expense
  final int page;
  final int limit;

  const TransactionFilter({
    this.salaryPeriodId,
    this.filter,
    this.startDate,
    this.endDate,
    this.transactionType,
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
    int? page,
    int? limit,
  }) {
    return TransactionFilter(
      salaryPeriodId:
          clearSalaryPeriodId ? null : (salaryPeriodId ?? this.salaryPeriodId),
      filter: clearFilter ? null : (filter ?? this.filter),
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      transactionType: clearTransactionType
          ? null
          : (transactionType ?? this.transactionType),
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Builds the query-parameter map, omitting nulls.
  Map<String, dynamic> toQueryParameters() {
    return {
      if (salaryPeriodId != null) 'salary_period_id': salaryPeriodId,
      if (filter != null) 'filter': filter,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (transactionType != null) 'transaction_type': transactionType,
      'page': page,
      'limit': limit,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.salaryPeriodId == salaryPeriodId &&
      other.filter == filter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.transactionType == transactionType &&
      other.page == page &&
      other.limit == limit;

  @override
  int get hashCode => Object.hash(
        salaryPeriodId,
        filter,
        startDate,
        endDate,
        transactionType,
        page,
        limit,
      );
}
