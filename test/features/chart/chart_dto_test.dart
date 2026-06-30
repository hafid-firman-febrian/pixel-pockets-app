import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/chart/data/dtos/chart_dto.dart';

void main() {
  test('ChartDto.fromJson parses labels and numeric series to doubles', () {
    final dto = ChartDto.fromJson(const {
      'labels': ['2026-06-29', '2026-06-30'],
      'income': [0, 2800000],
      'expense': [750000, 30000.5],
    });

    expect(dto.labels, ['2026-06-29', '2026-06-30']);
    expect(dto.income, [0.0, 2800000.0]);
    expect(dto.expense, [750000.0, 30000.5]);

    final domain = dto.toDomain();
    expect(domain.maxValue, 2800000.0);
    expect(domain.isEmpty, isFalse);
  });

  test('empty series → ChartData.isEmpty', () {
    final domain = ChartDto.fromJson(const {
      'labels': <String>[],
      'income': <num>[],
      'expense': <num>[],
    }).toDomain();
    expect(domain.isEmpty, isTrue);
    expect(domain.maxValue, 0);
  });
}
