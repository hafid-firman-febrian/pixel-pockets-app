import 'package:pixel_pocket/features/salary_period/domain/model/salary_period_model.dart';

class SalaryPeriodDto {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final double? salaryAmount;

  const SalaryPeriodDto({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.salaryAmount,
  });

  factory SalaryPeriodDto.fromJson(Map<String, dynamic> json) =>
      SalaryPeriodDto(
        id: json['id'] as int,
        name: json['name'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        salaryAmount: json['salaryAmount'] != null
            ? (json['salaryAmount'] as num).toDouble()
            : null,
      );

  SalaryPeriodModel toDomain() => SalaryPeriodModel(
    id: id,
    name: name,
    startDate: startDate,
    endDate: endDate,
    salaryAmount: salaryAmount,
  );
}
