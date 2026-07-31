# CLAUDE.md — Pixel Pocket Flutter

Pixel Pocket adalah aplikasi **local-first**: Drift (SQLite on-device) adalah source of truth, app jalan full offline. Tidak ada server/REST API. Google Sheets dipakai hanya sebagai backup/restore opsional (lihat `features/backup/`), bukan live DB.

## Stack

| Kebutuhan | Package |
|---|---|
| State management | `flutter_riverpod` |
| Local DB | `drift` (SQLite via `sqlite3_flutter_libs`) — source of truth, semua fitur baca/tulis lewat sini |
| Navigation | `go_router` |
| Chart | `fl_chart` |
| Backup (cloud, opsional) | `googleapis` (Sheets v4 + Drive v3) + `google_sign_in` (scope `drive.file`) — hanya dipakai di `features/backup/` |
| Models | Entity domain murni, **tanpa JSON** (tidak ada `fromJson`/`toJson`). Code-gen hanya untuk Drift (`build_runner` + `drift_dev`). |

---

## Arsitektur

Logic dan UI **wajib dipisah**. Feature yang memiliki data sendiri dibagi menjadi 4 blok utama (`data`, `domain`, `application`, `presentation`) dengan sub-lapisan berikut:

```
features/<feature>/
├── data/
│   ├── datasources/       ← Drift DAO — query AppDatabase, kembalikan domain model langsung
│   └── repositories/      ← pass-through tipis ke DAO; domain, Failure
├── domain/
│   └── models/            ← entity murni (tanpa JSON, Drift, Flutter, Riverpod)
├── application/
│   └── services/          ← business logic (tanpa Riverpod, tanpa widget)
└── presentation/
    ├── states/            ← Riverpod FutureProvider / StateProvider
    ├── controllers/       ← glue Riverpod: panggil service, invalidate state
    └── screens/           ← UI only
        └── widgets/       ← widget lokal milik screen di folder ini
```

**Penempatan `widgets/`:** default-nya bersarang di dalam `screens/`, bukan sejajar dengannya. Widget baru ikut konvensi ini kecuali memang dipakai lintas-screen dalam satu feature.

Tidak ada layer `dtos/`. Drift men-generate row class yang sudah *typed* langsung dari skema tabel yang kita kuasai sendiri (`core/database/tables.dart`) — bukan wire format eksternal yang butuh anti-corruption layer — jadi mapping row Drift → domain model dilakukan langsung inline di DAO.

### Aturan ketat

| Lapisan | Boleh | Tidak boleh |
|---|---|---|
| `domain/models` | entity murni, getter | JSON, Drift, Flutter, Riverpod |
| `data/datasources` | `AppDatabase` (Drift), domain model | Riverpod state, widget |
| `data/repositories` | datasource/DAO, domain, Failure | Drift langsung, widget |
| `application/services` | repository, domain | Riverpod state, widget |
| `presentation/states` | Riverpod, service via DI | Drift, parsing |
| `presentation/controllers` | Riverpod (Ref), service | Drift, parsing |
| `presentation/screens+widgets` | Widget, ref.watch | Drift, parsing, logic |

### Lapisan per feature

Tidak semua feature butuh 4 lapisan. Kondisi nyatanya:

| Feature | `data` | `domain` | `application` | `presentation` |
|---|:---:|:---:|:---:|:---:|
| `transactions`, `categories`, `salary_period`, `chart`, `dashboard`, `auth` | ✓ | ✓ | ✓ | ✓ |
| `backup` | ✓ | — | ✓ | ✓ |
| `settings` | — | — | — | ✓ |

Empat penyimpangan berikut **disengaja** — jangan "dirapikan" tanpa alasan kuat:

- **`backup` tanpa `domain/`.** `backup_serialization.dart` men-serialize row class Drift secara langsung, karena backup adalah snapshot database, bukan entity bisnis. Alasan yang sama membuatnya berada di root `data/`, bukan di `datasources/`.
- **`backup/application/auto_backup_coordinator.dart`** di root `application/`, bukan `services/` — dia scheduler (debounce timer + dirty flag), bukan business service.
- **`settings` presentation-only.** `settings_screen.dart` adalah permukaan komposisi: merender widget dan controller milik `auth`, `backup`, `categories`, dan `salary_period`, tanpa state sendiri.
- **`auth` menaruh widget di `presentation/widgets/`** (sejajar `screens/`), karena `PinScaffold`, `PinDots`, dan `PixelPinPad` dipakai bersama oleh Set PIN dan Unlock screen.

---

## Struktur Folder

```
lib/
├── core/
│   ├── cache/
│   │   └── cache_store.dart        ← wrapper shared_preferences (metadata lokal, bukan cache API)
│   ├── database/
│   │   ├── app_database.dart       ← Drift database + DAO registrations (schemaVersion 1)
│   │   ├── tables.dart             ← definisi tabel: Categories, SalaryPeriods, Transactions
│   │   └── default_categories.dart ← seed 18 kategori default
│   ├── error/
│   │   └── failure.dart
│   ├── router/
│   │   └── app_router.dart         ← go_router
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_color.dart          ← retro color scheme (lihat bagian Theme)
│   │   ├── app_sizing.dart
│   │   ├── app_spacing.dart
│   │   └── app_text_style.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   └── thousands_input_formatter.dart
│   └── widgets/                    ← komponen pixel dipakai lintas-feature
│       ├── pixel_card.dart
│       ├── pixel_button.dart
│       └── …                       ← chip, bottom nav, bottom sheet, confirm dialog, error view
├── features/
│   ├── auth/           ← PIN lock (local app lock) + Google sign-in (untuk backup)
│   ├── backup/         ← Google Sheets backup/restore + auto-backup
│   ├── categories/
│   ├── chart/
│   ├── dashboard/
│   ├── salary_period/
│   ├── settings/
│   └── transactions/
└── main.dart
```

Widget di `core/widgets/` dipakai lintas-feature. Widget yang cuma dipakai satu feature tetap tinggal di `features/<feature>/presentation/screens/widgets/`.

---

## Models

Semua domain model adalah entity murni — tidak ada `fromJson`/`toJson`. DAO memetakan row Drift ke model ini secara langsung.

### TransactionModel
```dart
class TransactionModel {
  final int id;
  final String transactionDate;
  final String transactionType;  // 'income' | 'expense'
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;    // hasil join ke categories
  final String? categoryColor;   // hex '#RRGGBB', hasil join ke categories
  final String? createdAt;
  final String? updatedAt;

  const TransactionModel({
    required this.id,
    required this.transactionDate,
    required this.transactionType,
    required this.amount,
    this.categoryId,
    this.description,
    this.categoryName,
    this.categoryColor,
    this.createdAt,
    this.updatedAt,
  });

  bool get isIncome => transactionType == 'income';
  bool get isExpense => transactionType == 'expense';
}
```

### TransactionFilter
```dart
class TransactionFilter {
  final int? salaryPeriodId;   // prioritas tertinggi — mengabaikan `filter`
  final String? filter;        // 'week' | 'month' | 'year' | 'custom'
  final String? startDate;     // 'YYYY-MM-DD', wajib jika filter == 'custom'
  final String? endDate;       // 'YYYY-MM-DD', wajib jika filter == 'custom'
  final String? transactionType; // 'income' | 'expense'
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
}
```

### CategoryModel
```dart
class CategoryModel {
  final int id;
  final String name;
  final String? color;
  final String type;  // 'income' | 'expense'

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    required this.type,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
```

### SalaryPeriodModel
```dart
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
```

### TransactionSummary (dashboard)
```dart
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  const TransactionSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });
}
```

### CategorySummary (dashboard — breakdown per kategori)
```dart
class CategorySummary {
  final int categoryId;
  final String name;
  final String? colorHex;
  final String type;      // 'income' | 'expense'
  final double total;
  final double percentage; // dari total per-type
  final int count;

  const CategorySummary({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.type,
    required this.total,
    required this.percentage,
    required this.count,
  });
}
```

### ChartData
```dart
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
  double get maxValue => [...income, ...expense].fold(0.0, (a, b) => a > b ? a : b);
}
```

---

## Pola Kode

### DAO (data/datasources/) — query Drift langsung
```dart
// features/categories/data/datasources/category_dao.dart
class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<List<CategoryModel>> getAll() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map(_toModel).toList();
  }

  Future<CategoryModel> create({required String name, required String color, required String type}) async {
    final id = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(name: name, color: Value(color), type: type),
        );
    return CategoryModel(id: id, name: name, color: color, type: type);
  }

  CategoryModel _toModel(Category row) =>
      CategoryModel(id: row.id, name: row.name, color: row.color, type: row.type);
}

final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(appDatabaseProvider)),
);
```

### Repository — pass-through tipis ke DAO, tanpa mapping DTO
```dart
// features/transactions/data/repositories/transaction_repository.dart
class TransactionRepository {
  TransactionRepository(this._dao);

  final TransactionDao _dao;

  Future<List<TransactionModel>> getAll(TransactionFilter filter) => _dao.getAll(filter);

  Future<TransactionModel> create(TransactionModel transaction) => _dao.create(transaction);
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(transactionDaoProvider)),
);
```

### Provider (presentation/states/)
```dart
// features/transactions/presentation/states/transaction_state.dart
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

// Data — otomatis refetch saat filter berubah
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionServiceProvider).list(filter); // lewat service
});
```

### Screen
```dart
// features/transactions/presentation/screens/transaction_screen.dart
class TransactionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(transactionsProvider);
    return asyncData.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
      data: (transactions) => TransactionList(transactions: transactions),
    );
  }
}
```

### Write via controller (presentation/controllers/)
```dart
// Panggil controller untuk mutasi; controller invalidate state setelahnya
await ref.read(transactionControllerProvider).delete(tx.id);

// Ganti filter — provider refetch otomatis
ref.read(transactionFilterProvider.notifier).state = TransactionFilter(
  salaryPeriodId: selectedPeriod.id,
);
```

---

## Theme — Retro Color Scheme

Semua warna ada di `AppColors` (`core/theme/app_color.dart`), bukan top-level constant.

```dart
// Expense
AppColors.groceries     // 0xFF7D9B76 — sage green
AppColors.beverage      // 0xFF5F8A8B — teal
AppColors.coffee        // 0xFF8B6355 — warm brown
AppColors.cigarettes    // 0xFF8C7B6B — taupe
AppColors.dailyNeeds    // 0xFFC4A882 — warm tan
AppColors.ecommerce     // 0xFF6B7C8D — slate blue
AppColors.entertainment // 0xFF9B6B8C — dusty mauve
AppColors.housing       // 0xFFB5847A — dusty rose
AppColors.meal          // 0xFFCC7358 — terracotta
AppColors.selfcare      // 0xFFA0856C — sand
AppColors.subscription  // 0xFF7B6D8D — muted purple
AppColors.transport     // 0xFF4A7C8C — dark teal
AppColors.other         // 0xFF8C8C7B — warm gray
// Income
AppColors.salary        // 0xFF6B8C5F — muted green
AppColors.freelance     // 0xFF5B7A8C — dusty blue
AppColors.investment    // 0xFF8C7A3D — golden brown
AppColors.bonus         // 0xFF8C5B3D — burnt sienna
AppColors.otherIncome   // 0xFF7A8C6B — sage olive
```

Parse hex string (kolom `color` dari tabel `categories`) ke `Color`:
```dart
AppColors.fromHex(category.color); // null/invalid → fallback ke AppColors.other
```

---

## Filter Transaksi & Summary

`TransactionDao`, `SummaryDao`, dan `ChartDao` menerima filter yang sama lewat `TransactionFilter`:

| Field | Nilai | Keterangan |
|---|---|---|
| `salaryPeriodId` | `int?` | Prioritas tertinggi — mengabaikan `filter` |
| `filter` | `week` \| `month` \| `year` \| `custom` | |
| `startDate` / `endDate` | `YYYY-MM-DD` | Wajib jika `filter == 'custom'` |
| `transactionType` | `income` \| `expense` | |
| `categoryId` | `int?` | Filter transaksi per kategori |

Catatan: kalau `salaryPeriodId` tidak match periode manapun, `TransactionDao`/`SummaryDao` fallback ke *unfiltered*, sedangkan `ChartDao` fallback ke bulan berjalan — perilaku ini masih divergen antar DAO, belum disamakan.
