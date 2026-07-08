import 'package:drift/drift.dart';
import 'package:pixel_pocket/core/database/app_database.dart';

const categoriesHeader = ['id', 'name', 'color', 'type'];
const salaryPeriodsHeader = ['id', 'name', 'start_date', 'end_date', 'salary_amount'];
const transactionsHeader = [
  'id', 'transaction_date', 'transaction_type', 'amount',
  'category_id', 'description', 'created_at', 'updated_at',
];

String _s(Object? v) => v == null ? '' : v.toString();
String? _nullable(Object? v) {
  final s = v?.toString() ?? '';
  return s.isEmpty ? null : s;
}
int _int(Object? v) => int.parse(v.toString());
int? _intN(Object? v) {
  final s = v?.toString() ?? '';
  return s.isEmpty ? null : int.parse(s);
}
double _double(Object? v) => double.parse(v.toString());
double? _doubleN(Object? v) {
  final s = v?.toString() ?? '';
  return s.isEmpty ? null : double.parse(s);
}

List<Object?> padRow(List<Object?> row, int width) => row.length >= width
    ? row
    : [...row, ...List.filled(width - row.length, '')];

List<Object?> categoryToRow(Category c) => [_s(c.id), _s(c.name), _s(c.color), _s(c.type)];

CategoriesCompanion categoryFromRow(List<Object?> r) => CategoriesCompanion(
  id: Value(_int(r[0])),
  name: Value(r[1].toString()),
  color: Value(_nullable(r[2])),
  type: Value(r[3].toString()),
);

List<Object?> salaryPeriodToRow(SalaryPeriod p) =>
  [_s(p.id), _s(p.name), _s(p.startDate), _s(p.endDate), _s(p.salaryAmount)];

SalaryPeriodsCompanion salaryPeriodFromRow(List<Object?> r) => SalaryPeriodsCompanion(
  id: Value(_int(r[0])),
  name: Value(r[1].toString()),
  startDate: Value(r[2].toString()),
  endDate: Value(r[3].toString()),
  salaryAmount: Value(_doubleN(r[4])),
);

List<Object?> transactionToRow(Transaction t) => [
  _s(t.id), _s(t.transactionDate), _s(t.transactionType), _s(t.amount),
  _s(t.categoryId), _s(t.description), _s(t.createdAt), _s(t.updatedAt),
];

TransactionsCompanion transactionFromRow(List<Object?> r) => TransactionsCompanion(
  id: Value(_int(r[0])),
  transactionDate: Value(r[1].toString()),
  transactionType: Value(r[2].toString()),
  amount: Value(_double(r[3])),
  categoryId: Value(_intN(r[4])),
  description: Value(_nullable(r[5])),
  createdAt: Value(_nullable(r[6])),
  updatedAt: Value(_nullable(r[7])),
);
