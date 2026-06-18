class SalaryPeriodModel {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final double? salaryAmount;

  const SalaryPeriodModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.salaryAmount,
  });
}
