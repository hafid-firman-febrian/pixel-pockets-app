import 'package:pixel_pocket/features/chart/domain/models/chart_data.dart';


class ChartDto {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;

  const ChartDto({
    required this.labels,
    required this.income,
    required this.expense,
  });

  factory ChartDto.fromJson(Map<String, dynamic> json) => ChartDto(
        labels: (json['labels'] as List).map((e) => e as String).toList(),
        income: _toDoubles(json['income']),
        expense: _toDoubles(json['expense']),
      );

  static List<double> _toDoubles(dynamic list) =>
      (list as List).map((e) => (e as num).toDouble()).toList();

  ChartData toDomain() =>
      ChartData(labels: labels, income: income, expense: expense);
}
