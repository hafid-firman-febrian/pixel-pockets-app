class ChartData {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;

  const ChartData({
    required this.labels,
    required this.income,
    required this.expense,
  });

  bool get isEmpty => labels.isEmpty;

  double get maxValue {
    final values = [...income, ...expense];
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b);
  }
}
