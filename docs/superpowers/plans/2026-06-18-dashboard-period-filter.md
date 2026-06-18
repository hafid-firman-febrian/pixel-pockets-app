# Dashboard Period Filter Implementation Plan

> **Catatan:** Langkah test sengaja DIHILANGKAN sesuai permintaan — Anda menulis test sendiri setelah implementasi. Tiap task tetap diakhiri `flutter analyze` (tidak menambah issue) + commit. Test suite yang sudah ada (`flutter test`) tetap harus hijau.

**Goal:** Membuat `PeriodFilterCard` di dashboard bisa ditekan untuk memilih salary period dari `GET /api/salary-periods`, lalu pilihan itu memfilter `GET /api/summary` yang asli.

**Architecture:** Tambah fitur baru `salary_period` (data → domain, repository, service, state provider) untuk memuat daftar period. Di dashboard: tambah `selectedPeriodProvider`, sambungkan summary data source ke API asli dengan query `salary_period_id`, dan ubah `PeriodFilterCard` menjadi `ConsumerWidget` dengan bottom-sheet picker. Mengubah pilihan otomatis me-refetch summary lewat `ref.watch` Riverpod.

**Tech Stack:** Flutter, flutter_riverpod, dio, go_router. JSON manual (tanpa codegen).

## Global Constraints

- Nama package `pixel_pocket`. Semua import pakai bentuk absolut `package:pixel_pocket/...`.
- Folder fitur baru: `lib/features/salary_period/` (singular — folder kosong sudah ada).
- Aturan Clean Architecture berlaku: domain model murni; DTO pegang JSON; repository map DTO→domain dan ubah `DioException`→`Failure`; service pegang business logic (tanpa Riverpod state); provider DI diletakkan di bawah tiap file class.
- Field `SalaryPeriod` (sesuai CLAUDE.md): `id:int`, `name:String`, `startDate:String`, `endDate:String`, `salaryAmount:double?`. API mengembalikan key camelCase.
- Default `selectedPeriodProvider` = `null`, artinya "Semua Periode" (tidak mengirim `salary_period_id`).
- Tidak ada trailer co-author di commit.
- Pengaman tiap task: `flutter analyze` tidak menambah issue baru; `flutter test` (suite yang ada) tetap lulus.
- **Test untuk kode baru ditulis belakangan oleh Anda** — tidak termasuk langkah di sini.

## File map

Baru (fitur salary_period):
- `lib/features/salary_period/domain/models/salary_period.dart`
- `lib/features/salary_period/data/dtos/salary_period_dto.dart`
- `lib/features/salary_period/data/datasources/salary_period_remote_data_source.dart`
- `lib/features/salary_period/data/repositories/salary_period_repository.dart`
- `lib/features/salary_period/application/services/salary_period_service.dart`
- `lib/features/salary_period/presentation/states/salary_period_state.dart`

Diubah (dashboard):
- `lib/features/dashboard/data/datasources/dashboard_remote_data_source.dart`
- `lib/features/dashboard/data/repositories/dashboard_repository.dart`
- `lib/features/dashboard/application/services/dashboard_service.dart`
- `lib/features/dashboard/presentation/states/dashboard_state.dart`
- `lib/features/dashboard/presentation/screens/widgets/period_filter_card.dart`

> **Catatan test (untuk nanti):** kandidat test yang berguna saat Anda kerjakan sendiri: (1) `SalaryPeriodDto.fromJson`/`toDomain` termasuk `salaryAmount` null; (2) `salaryPeriodsProvider` me-map DTO→domain dan memunculkan `Failure` saat `DioException` (override `salaryPeriodRemoteDataSourceProvider` dgn fake); (3) `dashboardSummaryProvider` mengirim id period terpilih ke service dan refetch saat `selectedPeriodProvider` berubah (override `dashboardRepositoryProvider` dgn fake pencatat).

---

## Task 1: `SalaryPeriod` domain model + DTO

**Files:**
- Create: `lib/features/salary_period/domain/models/salary_period.dart`
- Create: `lib/features/salary_period/data/dtos/salary_period_dto.dart`

**Interfaces:**
- Produces: `SalaryPeriod` (murni: `id`, `name`, `startDate`, `endDate`, `salaryAmount?`); `SalaryPeriodDto` dengan `factory SalaryPeriodDto.fromJson(Map<String,dynamic>)` dan `SalaryPeriod toDomain()`.

> **Penjelasan (belajar):** Mulai dari lapisan paling dalam (domain) lalu DTO — sesuai prinsip "dependency mengarah ke dalam". Domain `SalaryPeriod` tidak tahu soal JSON; `SalaryPeriodDto` yang pegang `fromJson`. Logika nyata satu-satunya di sini: `salaryAmount` yang boleh `null` dan cast `num→double`. (Saat menulis test nanti, fokuskan ke `fromJson`/`toDomain`.)

- [ ] **Step 1: Buat domain model**

Create `lib/features/salary_period/domain/models/salary_period.dart`:
```dart
/// A salary period — pure domain entity. No JSON, no Dio.
class SalaryPeriod {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final double? salaryAmount;

  const SalaryPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.salaryAmount,
  });
}
```

- [ ] **Step 2: Buat DTO**

Create `lib/features/salary_period/data/dtos/salary_period_dto.dart`:
```dart
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';

/// Wire representation of a salary period. Owns JSON parsing so the domain
/// model stays pure. The API returns camelCase keys.
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

  factory SalaryPeriodDto.fromJson(Map<String, dynamic> json) => SalaryPeriodDto(
        id: json['id'] as int,
        name: json['name'] as String,
        startDate: json['startDate'] as String,
        endDate: json['endDate'] as String,
        salaryAmount: json['salaryAmount'] != null
            ? (json['salaryAmount'] as num).toDouble()
            : null,
      );

  SalaryPeriod toDomain() => SalaryPeriod(
        id: id,
        name: name,
        startDate: startDate,
        endDate: endDate,
        salaryAmount: salaryAmount,
      );
}
```

- [ ] **Step 3: Analyze + commit**

```bash
flutter analyze
git add lib/features/salary_period
git commit -m "feat(salary_period): add SalaryPeriod domain model + DTO"
```
Expected: analyze tidak menambah issue.

---

## Task 2: `salary_period` data source, repository, service, state

**Files:**
- Create: `lib/features/salary_period/data/datasources/salary_period_remote_data_source.dart`
- Create: `lib/features/salary_period/data/repositories/salary_period_repository.dart`
- Create: `lib/features/salary_period/application/services/salary_period_service.dart`
- Create: `lib/features/salary_period/presentation/states/salary_period_state.dart`

**Interfaces:**
- Consumes: `dioProvider` (`lib/core/api/api_client.dart`); `ApiEndpoints.salaryPeriods` (`lib/core/api/api_endpoints.dart`); `Failure`/`Failure.fromDio` (`lib/core/error/failure.dart`); `SalaryPeriodDto`, `SalaryPeriod` (Task 1).
- Produces:
  - `SalaryPeriodRemoteDataSource(Dio)` dengan `Future<List<SalaryPeriodDto>> getAll()`; `salaryPeriodRemoteDataSourceProvider`.
  - `SalaryPeriodRepository(SalaryPeriodRemoteDataSource)` dengan `Future<List<SalaryPeriod>> getAll()`; `salaryPeriodRepositoryProvider`.
  - `SalaryPeriodService(SalaryPeriodRepository)` dengan `Future<List<SalaryPeriod>> list()`; `salaryPeriodServiceProvider`.
  - `salaryPeriodsProvider : FutureProvider<List<SalaryPeriod>>`.

> **Penjelasan (belajar):** Ini melengkapi rantai data fitur baru: DataSource (bicara ke Dio, kembalikan DTO) → Repository (ubah DTO→domain, ubah `DioException`→`Failure`) → Service (titik logika bisnis, di sini cuma meneruskan) → State (provider Riverpod yang dibaca UI). Perhatikan: hanya repository yang menangkap `DioException`; datasource membiarkannya naik, service & state tidak tahu soal Dio. Saat menulis test nanti, override `salaryPeriodRemoteDataSourceProvider` dengan fake agar tanpa jaringan.

- [ ] **Step 1: Buat data source**

Create `lib/features/salary_period/data/datasources/salary_period_remote_data_source.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/salary_period/data/dtos/salary_period_dto.dart';

/// Raw transport for salary periods. Unwraps the `"data"` envelope and returns
/// DTOs. Throws [DioException] on failure (mapped to Failure by the repo).
class SalaryPeriodRemoteDataSource {
  SalaryPeriodRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SalaryPeriodDto>> getAll() async {
    final response = await _dio.get(ApiEndpoints.salaryPeriods);
    final list = response.data['data'] as List;
    return list
        .map((e) => SalaryPeriodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final salaryPeriodRemoteDataSourceProvider =
    Provider<SalaryPeriodRemoteDataSource>(
  (ref) => SalaryPeriodRemoteDataSource(ref.watch(dioProvider)),
);
```

- [ ] **Step 2: Buat repository**

Create `lib/features/salary_period/data/repositories/salary_period_repository.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';

/// Maps salary-period DTOs → domain models and converts transport errors.
class SalaryPeriodRepository {
  SalaryPeriodRepository(this._remote);

  final SalaryPeriodRemoteDataSource _remote;

  Future<List<SalaryPeriod>> getAll() async {
    try {
      final dtos = await _remote.getAll();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final salaryPeriodRepositoryProvider = Provider<SalaryPeriodRepository>(
  (ref) => SalaryPeriodRepository(ref.watch(salaryPeriodRemoteDataSourceProvider)),
);
```

- [ ] **Step 3: Buat service**

Create `lib/features/salary_period/application/services/salary_period_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/data/repositories/salary_period_repository.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';

/// Business logic for salary periods.
class SalaryPeriodService {
  SalaryPeriodService(this._repo);

  final SalaryPeriodRepository _repo;

  Future<List<SalaryPeriod>> list() => _repo.getAll();
}

final salaryPeriodServiceProvider = Provider<SalaryPeriodService>(
  (ref) => SalaryPeriodService(ref.watch(salaryPeriodRepositoryProvider)),
);
```

- [ ] **Step 4: Buat state provider**

Create `lib/features/salary_period/presentation/states/salary_period_state.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/salary_period/application/services/salary_period_service.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';

/// All salary periods, for the dashboard period picker.
final salaryPeriodsProvider = FutureProvider<List<SalaryPeriod>>((ref) {
  return ref.watch(salaryPeriodServiceProvider).list();
});
```

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze
git add lib/features/salary_period
git commit -m "feat(salary_period): add data source, repository, service, and state provider"
```
Expected: analyze tidak menambah issue.

---

## Task 3: Sambungkan summary API asli + state period terpilih

**Files:**
- Modify: `lib/features/dashboard/data/datasources/dashboard_remote_data_source.dart`
- Modify: `lib/features/dashboard/data/repositories/dashboard_repository.dart`
- Modify: `lib/features/dashboard/application/services/dashboard_service.dart`
- Modify: `lib/features/dashboard/presentation/states/dashboard_state.dart`

**Interfaces:**
- Consumes: `dioProvider`; `ApiEndpoints.summary`; `Failure`; `SummaryDto` (`lib/features/dashboard/data/dtos/summary_dto.dart`, punya `fromJson` + `toDomain`); `TransactionSummary`; `SalaryPeriod` (Task 1).
- Produces:
  - `DashboardRemoteDataSource(Dio)` dengan `Future<SummaryDto> getSummary(int? salaryPeriodId)`.
  - `DashboardRepository.getSummary(int? periodId)`, `DashboardService.summary(int? periodId)`.
  - `PeriodSelection` (sealed): `AutoPeriod` (default — tanggal hari ini), `AllPeriods` (Semua Periode), `SpecificPeriod(SalaryPeriod period)`.
  - `selectedPeriodProvider : StateProvider<PeriodSelection>` (default `AutoPeriod`).
  - `effectivePeriodProvider : FutureProvider<SalaryPeriod?>` (resolusi pilihan → period nyata; null = tanpa filter).
  - `dashboardSummaryProvider` membaca `effectivePeriodProvider` lalu mengirim `period?.id`.

> **Penjelasan (belajar):** Datasource/repo/service di Step 1–3 sama seperti sebelumnya (stub → API asli; pola `queryParameters: { if (id != null) 'salary_period_id': id }`). Yang baru ada di Step 4 (state). Karena **default period = tanggal hari ini** dan daftar period itu async, satu `SalaryPeriod?` tidak cukup (hanya 2 keadaan), jadi kita pakai `sealed class PeriodSelection` (auto/all/specific — pola sama seperti `AuthState`). `effectivePeriodProvider` me-resolusi pilihan: `AutoPeriod` menunggu `salaryPeriodsProvider` lalu mencari period yang memuat hari ini, `AllPeriods` → null, `SpecificPeriod` → period itu. `dashboardSummaryProvider` `await ref.watch(effectivePeriodProvider.future)`, jadi ganti pilihan → refetch otomatis.

- [ ] **Step 1: Update data source ke API asli**

Ganti SELURUH isi `lib/features/dashboard/data/datasources/dashboard_remote_data_source.dart` dengan:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';

/// Raw transport for the dashboard summary. Unwraps the `"data"` envelope and
/// returns a DTO. Throws [DioException] on failure (mapped to Failure by repo).
class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._dio);

  final Dio _dio;

  Future<SummaryDto> getSummary(int? salaryPeriodId) async {
    final response = await _dio.get(
      ApiEndpoints.summary,
      queryParameters: {
        if (salaryPeriodId != null) 'salary_period_id': salaryPeriodId,
      },
    );
    return SummaryDto.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(ref.watch(dioProvider)),
);
```

- [ ] **Step 2: Update repository (param id + mapping Failure)**

Ganti SELURUH isi `lib/features/dashboard/data/repositories/dashboard_repository.dart` dengan:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Maps the summary DTO to the domain model and converts transport errors.
class DashboardRepository {
  DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  Future<TransactionSummary> getSummary(int? periodId) async {
    try {
      final dto = await _remote.getSummary(periodId);
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardRemoteDataSourceProvider)),
);
```

- [ ] **Step 3: Update service**

Ganti SELURUH isi `lib/features/dashboard/application/services/dashboard_service.dart` dengan:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Business logic for the dashboard.
class DashboardService {
  DashboardService(this._repo);

  final DashboardRepository _repo;

  Future<TransactionSummary> summary(int? periodId) =>
      _repo.getSummary(periodId);
}

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(dashboardRepositoryProvider)),
);
```

- [ ] **Step 4: Tambah `PeriodSelection`, `effectivePeriodProvider`, dan sambungkan summary**

Ganti SELURUH isi `lib/features/dashboard/presentation/states/dashboard_state.dart` dengan:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';

/// Cara period dashboard dipilih (pola sama seperti AuthState).
/// - [AutoPeriod]     : default — pakai period yang memuat tanggal hari ini.
/// - [AllPeriods]     : "Semua Periode" (tanpa filter).
/// - [SpecificPeriod] : period yang dipilih user.
sealed class PeriodSelection {
  const PeriodSelection();
}

class AutoPeriod extends PeriodSelection {
  const AutoPeriod();
}

class AllPeriods extends PeriodSelection {
  const AllPeriods();
}

class SpecificPeriod extends PeriodSelection {
  const SpecificPeriod(this.period);
  final SalaryPeriod period;
}

/// Pilihan period saat ini. Default [AutoPeriod] → ditentukan tanggal hari ini.
/// Mengubah ini me-refetch [dashboardSummaryProvider].
final selectedPeriodProvider =
    StateProvider<PeriodSelection>((ref) => const AutoPeriod());

/// Period efektif hasil resolusi pilihan + daftar period.
/// null = tanpa filter (Semua Periode, atau auto tapi tak ada period hari ini).
final effectivePeriodProvider = FutureProvider<SalaryPeriod?>((ref) async {
  final selection = ref.watch(selectedPeriodProvider);
  switch (selection) {
    case AllPeriods():
      return null;
    case SpecificPeriod(:final period):
      return period;
    case AutoPeriod():
      final periods = await ref.watch(salaryPeriodsProvider.future);
      return _periodForToday(periods, _todayFloor());
  }
});

/// Dashboard summary, difilter oleh period efektif.
final dashboardSummaryProvider =
    FutureProvider<TransactionSummary>((ref) async {
  final period = await ref.watch(effectivePeriodProvider.future);
  return ref.watch(dashboardServiceProvider).summary(period?.id);
});

/// Tanggal hari ini tanpa komponen jam (untuk perbandingan inklusif).
DateTime _todayFloor() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

/// Period pertama yang rentang [startDate, endDate]-nya memuat [today]
/// (inklusif), atau null bila tidak ada.
SalaryPeriod? _periodForToday(List<SalaryPeriod> periods, DateTime today) {
  for (final p in periods) {
    final start = DateTime.parse(p.startDate);
    final end = DateTime.parse(p.endDate);
    if (!today.isBefore(start) && !today.isAfter(end)) return p;
  }
  return null;
}
```

- [ ] **Step 5: Analyze + commit**

```bash
flutter analyze
git add lib/features/dashboard
git commit -m "feat(dashboard): wire real summary API filtered by selected period"
```
Expected: analyze tidak menambah issue. (Dashboard kini memanggil API asli saat runtime; smoke test yang ada tetap lulus karena tidak pernah mencapai dashboard.)

---

## Task 4: `PeriodFilterCard` interaktif (bottom-sheet picker)

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/widgets/period_filter_card.dart`

**Interfaces:**
- Consumes: `effectivePeriodProvider`, `selectedPeriodProvider`, `PeriodSelection`/`AllPeriods`/`SpecificPeriod` (Task 3), `salaryPeriodsProvider` (Task 2), `SalaryPeriod` (Task 1); tema (`AppColors`, `AppSpacing`, `AppTextStyles`).

> **Penjelasan (belajar):** Card menampilkan label dari `effectivePeriodProvider` (bukan langsung `selectedPeriodProvider`) karena mode auto perlu meresolusi "period hari ini" dulu — pakai `.maybeWhen(data: …, orElse: '…')` agar saat loading tampil `…`. Sheet menjadi `ConsumerStatefulWidget` supaya bisa menyimpan **filter tahun** (state UI lokal): `_selectedYear` default `DateTime.now().year`. Tahun diambil dari `startDate` tiap period — filtering **client-side** atas list yang sudah dimuat, tanpa request baru. Memilih item men-set `selectedPeriodProvider` ke `AllPeriods()` atau `SpecificPeriod(period)`.

- [ ] **Step 1: Ganti widget dengan versi interaktif**

Ganti SELURUH isi `lib/features/dashboard/presentation/screens/widgets/period_filter_card.dart` dengan:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period.dart';
import 'package:pixel_pocket/features/salary_period/presentation/states/salary_period_state.dart';

/// Shows the effective period and opens a picker on tap. Selecting a period
/// updates [selectedPeriodProvider], which re-runs the summary.
class PeriodFilterCard extends ConsumerWidget {
  const PeriodFilterCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = ref.watch(effectivePeriodProvider).maybeWhen(
          data: (p) => p?.name ?? 'Semua Periode',
          orElse: () => '…',
        );

    return InkWell(
      onTap: () => _openPicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Padding(
          padding: AppSpacing.card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PERIOD', style: AppTextStyles.bodyNormal),
              Row(
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => const _PeriodPickerSheet(),
    );
  }
}

/// Bottom-sheet: filter tahun (client-side, default tahun sekarang) +
/// "Semua Periode" + daftar period pada tahun terpilih.
class _PeriodPickerSheet extends ConsumerStatefulWidget {
  const _PeriodPickerSheet();

  @override
  ConsumerState<_PeriodPickerSheet> createState() => _PeriodPickerSheetState();
}

class _PeriodPickerSheetState extends ConsumerState<_PeriodPickerSheet> {
  int _selectedYear = DateTime.now().year;

  int _yearOf(SalaryPeriod p) => DateTime.parse(p.startDate).year;

  @override
  Widget build(BuildContext context) {
    final periodsAsync = ref.watch(salaryPeriodsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.section),
        child: periodsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Gagal memuat periode: $e', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.section),
                TextButton(
                  onPressed: () => ref.invalidate(salaryPeriodsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
          data: (periods) {
            // Tahun unik dari semua period (terbaru dulu).
            final years = periods.map(_yearOf).toSet().toList()
              ..sort((a, b) => b.compareTo(a));
            // Filter client-side: hanya period di tahun terpilih.
            final filtered =
                periods.where((p) => _yearOf(p) == _selectedYear).toList();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (years.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpacing.card,
                    child: Row(
                      children: [
                        for (final year in years)
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.s4),
                            child: ChoiceChip(
                              label: Text('$year'),
                              selected: year == _selectedYear,
                              onSelected: (_) =>
                                  setState(() => _selectedYear = year),
                            ),
                          ),
                      ],
                    ),
                  ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('Semua Periode'),
                        onTap: () {
                          ref.read(selectedPeriodProvider.notifier).state =
                              const AllPeriods();
                          Navigator.of(context).pop();
                        },
                      ),
                      for (final period in filtered)
                        ListTile(
                          title: Text(period.name),
                          subtitle:
                              Text('${period.startDate} → ${period.endDate}'),
                          onTap: () {
                            ref.read(selectedPeriodProvider.notifier).state =
                                SpecificPeriod(period);
                            Navigator.of(context).pop();
                          },
                        ),
                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.s24),
                          child: Text(
                            'Tidak ada periode untuk tahun $_selectedYear',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

> Layar dashboard sudah merender `const PeriodFilterCard()` dan meng-import-nya — tidak perlu diubah. (`const` tetap valid karena `PeriodFilterCard` punya constructor `const`.)

- [ ] **Step 2: Analyze + jalankan test suite yang ada**

```bash
flutter analyze
flutter test
```
Expected: analyze tidak menambah issue; smoke test yang ada tetap lulus.

- [ ] **Step 3: Verifikasi manual (jalankan app)**

Run: `flutter run` (dengan akun Google sudah login agar interceptor melampirkan token).
Cek:
1. Saat dibuka, label PERIOD otomatis menampilkan **period yang memuat tanggal hari ini** (atau "Semua Periode" bila tidak ada yang cocok), dan summary sudah terfilter untuk period itu.
2. Mengetuk card PERIOD membuka bottom sheet: ada **chip tahun** dengan **tahun sekarang aktif**, di bawahnya "Semua Periode" + daftar period **tahun itu saja**.
3. Mengganti chip tahun mengubah daftar period (client-side, tanpa loading ulang).
4. Memilih satu period menutup sheet, label card berubah jadi nama period itu, dan angka summary refetch.
5. Memilih "Semua Periode" mereset filter (tanpa `salary_period_id`).

> Bila API error (mis. belum login), `summaryAsync.when(error: ...)` di dashboard menampilkan teks error — itu wajar.

- [ ] **Step 4: Commit**

```bash
git add lib/features/dashboard/presentation/screens/widgets/period_filter_card.dart
git commit -m "feat(dashboard): interactive period filter card with bottom-sheet picker"
```

---

## Catatan akhir

Setelah keempat task selesai dan Anda menulis test sendiri (lihat "Catatan test" di File map), jalankan `flutter test` penuh untuk memastikan semuanya hijau sebelum merge branch `feature/dashboard-period-filter`.
