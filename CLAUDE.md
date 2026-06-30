# CLAUDE.md — Pixel Pocket Flutter

## Stack

| Kebutuhan | Package |
|---|---|
| State management | `flutter_riverpod` |
| HTTP client | `dio` |
| Navigation | `go_router` |
| Chart | `fl_chart` |
| JSON | Manual `toJson` / `fromJson` — **tanpa freezed, tanpa code gen** |

---

## Arsitektur

Logic dan UI **wajib dipisah**. Setiap feature dibagi menjadi 4 blok utama (`data`, `domain`, `application`, `presentation`) dengan sub-lapisan berikut:

```
features/<feature>/
├── data/
│   ├── datasources/   ← Dio/SDK wrapper, kembalikan DTO, lempar DioException
│   ├── dtos/          ← fromJson / toJson + fromDomain / toDomain
│   └── repositories/  ← map DTO↔domain, DioException → Failure
├── domain/
│   └── models/        ← entity murni (tanpa JSON, Dio, Flutter)
├── application/
│   └── services/      ← business logic (tanpa Riverpod, tanpa widget)
└── presentation/
    ├── states/        ← Riverpod FutureProvider / StateProvider
    ├── controllers/   ← glue Riverpod: panggil service, invalidate state
    ├── screens/       ← UI only
    └── widgets/
```

### Aturan ketat

| Lapisan | Boleh | Tidak boleh |
|---|---|---|
| `domain/models` | entity murni, getter | JSON, Dio, Flutter, Riverpod |
| `data/dtos` | fromJson/toJson, map ke domain | Dio, widget |
| `data/datasources` | Dio, DTO, endpoints | map domain, map Failure, widget |
| `data/repositories` | datasource, DTO, domain, Failure | Dio langsung, widget |
| `application/services` | repository, domain | Riverpod state, widget, Dio |
| `presentation/states` | Riverpod, service via DI | Dio, parsing |
| `presentation/controllers` | Riverpod (Ref), service | Dio, parsing |
| `presentation/screens+widgets` | Widget, ref.watch | Dio, parsing, logic |

---

## Struktur Folder

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart         ← Dio instance + baseUrl + interceptor
│   │   └── api_endpoints.dart      ← semua URL string constant
│   ├── error/
│   │   └── failure.dart
│   ├── theme/
│   │   └── app_theme.dart          ← retro color scheme
│   └── utils/
│       └── currency_formatter.dart
├── features/
│   ├── dashboard/
│   ├── transactions/
│   ├── categories/
│   ├── salary_periods/
│   └── backup/
└── main.dart
```

---

## API

| Environment | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator | `http://localhost:3000` |
| Production | `https://<project>.vercel.app` |

### Konvensi response

Semua response selalu dibungkus key `"data"`:

```dart
// Single object
final data = response.data['data'];
final model = SomeModel.fromJson(data);

// List
final list = response.data['data'] as List;
final models = list.map((e) => SomeModel.fromJson(e)).toList();

// List dengan pagination
final list = response.data['data'] as List;
final meta = response.data['meta'];
```

---

## Models

### TransactionModel
```dart
class TransactionModel {
  final int id;
  final String transactionDate;
  final String transactionType;  // 'income' | 'expense'
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor;   // hex '#RRGGBB'
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

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      transactionDate: json['transactionDate'],
      transactionType: json['transactionType'],
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'],
      description: json['description'],
      categoryName: json['categoryName'],
      categoryColor: json['categoryColor'],
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'transaction_date': transactionDate,
    'transaction_type': transactionType,
    'amount': amount,
    if (categoryId != null) 'category_id': categoryId,
    if (description != null) 'description': description,
  };
}
```

### CategoryModel
```dart
class CategoryModel {
  final int id;
  final String name;
  final String? color;
  final String type;  // 'income' | 'expense' | 'both'

  const CategoryModel({
    required this.id,
    required this.name,
    this.color,
    required this.type,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    id: json['id'],
    name: json['name'],
    color: json['color'],
    type: json['type'],
  );
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

  factory SalaryPeriodModel.fromJson(Map<String, dynamic> json) => SalaryPeriodModel(
    id: json['id'],
    name: json['name'],
    startDate: json['startDate'],
    endDate: json['endDate'],
    salaryAmount: json['salaryAmount'] != null
        ? (json['salaryAmount'] as num).toDouble()
        : null,
  );
}
```

### SummaryModel
```dart
class SummaryModel {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  const SummaryModel({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
    totalIncome: (json['total_income'] as num).toDouble(),
    totalExpense: (json['total_expense'] as num).toDouble(),
    balance: (json['balance'] as num).toDouble(),
    transactionCount: json['transaction_count'],
  );
}
```

### ChartModel
```dart
class ChartModel {
  final List<String> labels;
  final List<double> income;
  final List<double> expense;

  const ChartModel({
    required this.labels,
    required this.income,
    required this.expense,
  });

  factory ChartModel.fromJson(Map<String, dynamic> json) => ChartModel(
    labels: List<String>.from(json['labels']),
    income: List<double>.from(
      (json['income'] as List).map((e) => (e as num).toDouble()),
    ),
    expense: List<double>.from(
      (json['expense'] as List).map((e) => (e as num).toDouble()),
    ),
  );
}
```

---

## Pola Kode

### Repository
```dart
// features/transactions/data/repositories/transaction_repository.dart
class TransactionRepository {
  TransactionRepository(this._remote);

  final TransactionRemoteDataSource _remote; // tidak pegang Dio langsung

  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    try {
      final dtos = await _remote.getAll(filter);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(ref.watch(transactionRemoteDataSourceProvider)),
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

```dart
// Expense
const kColorGroceries     = Color(0xFF7D9B76); // sage green
const kColorBeverage      = Color(0xFF5F8A8B); // teal
const kColorCoffee        = Color(0xFF8B6355); // warm brown
const kColorCigarettes    = Color(0xFF8C7B6B); // taupe
const kColorDailyNeeds    = Color(0xFFC4A882); // warm tan
const kColorEcommerce     = Color(0xFF6B7C8D); // slate blue
const kColorEntertainment = Color(0xFF9B6B8C); // dusty mauve
const kColorHousing       = Color(0xFFB5847A); // dusty rose
const kColorMeal          = Color(0xFFCC7358); // terracotta
const kColorSelfcare      = Color(0xFFA0856C); // sand
const kColorSubscription  = Color(0xFF7B6D8D); // muted purple
const kColorTransport     = Color(0xFF4A7C8C); // dark teal
const kColorOther         = Color(0xFF8C8C7B); // warm gray
// Income
const kColorSalary        = Color(0xFF6B8C5F); // muted green
const kColorFreelance     = Color(0xFF5B7A8C); // dusty blue
const kColorInvestment    = Color(0xFF8C7A3D); // golden brown
const kColorBonus         = Color(0xFF8C5B3D); // burnt sienna
const kColorOtherIncome   = Color(0xFF7A8C6B); // sage olive
```

Helper parse hex string dari API ke Color:
```dart
Color hexToColor(String hex) {
  final sanitized = hex.replaceAll('#', '');
  return Color(int.parse('FF$sanitized', radix: 16));
}
```

---

## Filter Tanggal

Semua endpoint transactions & summary menerima filter yang sama:

| Parameter | Nilai | Keterangan |
|---|---|---|
| `salary_period_id` | `int` | Prioritas tertinggi — mengabaikan `filter` |
| `filter` | `week` \| `month` \| `year` \| `custom` | |
| `start_date` | `YYYY-MM-DD` | Wajib jika `filter=custom` |
| `end_date` | `YYYY-MM-DD` | Wajib jika `filter=custom` |
| `transaction_type` | `income` \| `expense` | |
| `category_id` | `int` | Filter transaksi per kategori |

---

## Endpoints Lengkap

| Method | Endpoint | Keterangan |
|---|---|---|
| GET | `/api/categories` | List semua kategori |
| POST | `/api/categories/seed` | Seed 18 kategori default |
| GET | `/api/salary-periods` | List semua salary period |
| POST | `/api/salary-periods/seed` | Generate salary period otomatis |
| GET | `/api/transactions` | List transaksi (filter + pagination) |
| GET | `/api/transactions/:id` | Detail transaksi |
| POST | `/api/transactions` | Buat transaksi |
| PUT | `/api/transactions/:id` | Update transaksi |
| DELETE | `/api/transactions/:id` | Hapus transaksi |
| GET | `/api/summary` | Total income/expense/balance |
| GET | `/api/summary/by-category` | Breakdown per kategori |
| GET | `/api/summary/chart` | Time-series harian untuk chart |
| POST | `/api/backup/spreadsheet` | Export ke Google Sheets |
