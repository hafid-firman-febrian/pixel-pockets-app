# Clean Architecture Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure every feature into the 4-layer Clean Architecture from `_imageRef/riverpod_architecture.png` (Presentation → Application → Domain → Data) with no behavior change.

**Architecture:** Each feature gets `data/{datasources,dtos,repositories}`, `domain/models`, `application/services`, `presentation/{states,controllers,screens,widgets}`. DTOs own all JSON; domain models are pure; repositories map DTO↔domain and convert `DioException`→`Failure`; services hold business logic (no Riverpod); controllers are Riverpod glue. DI providers are co-located at the bottom of each class file.

**Tech Stack:** Flutter, flutter_riverpod, dio, go_router, fl_chart. Manual JSON (no codegen).

## Global Constraints

- Package name is `pixel_pocket`. **All imports in new/edited files use `package:pixel_pocket/...` absolute imports** (no `../..` relative imports) for robustness against the folder moves.
- **Domain class names are preserved** (`TransactionModel`, `CategoryModel`, `TransactionSummary`) so UI consumers only need import-path changes, not symbol renames. Domain models become *pure* (no `fromJson`/`toJson`/query-building).
- **No behavior change.** This is a structural refactor. The regression guard for every task is: `flutter analyze` introduces no new issues, and `flutter test` passes.
- Use `git mv` to relocate files so history is preserved; use `git rm` for files that are split/replaced.
- After every task: run `flutter analyze` then `flutter test`, then commit.

## Target structure (all features)

```
features/<feature>/
├── data/
│   ├── datasources/   ← Dio/SDK wrapper; returns DTOs; throws DioException
│   ├── dtos/          ← fromJson/toJson + fromDomain()/toDomain()
│   └── repositories/  ← DTO↔domain mapping; DioException → Failure
├── domain/
│   └── models/        ← pure entities
├── application/
│   └── services/      ← business logic (no Riverpod)
└── presentation/
    ├── states/        ← Riverpod FutureProvider/StateProvider
    ├── controllers/   ← Riverpod glue (holds Ref, invalidates)
    ├── screens/
    └── widgets/
```

---

## Pre-flight: capture baseline

- [ ] **Step 1: Record current analyzer + test state**

Run:
```bash
flutter analyze | tee /tmp/analyze_baseline.txt
flutter test
```
Expected: note any PRE-EXISTING analyzer infos/warnings (e.g. unused imports/variables in `transaction_screen.dart`). These are the baseline — the migration must not ADD new issues. `flutter test` must already PASS (1 smoke test). If it doesn't pass before we start, stop and report.

---

## Task 1: Migrate `categories`

**Files:**
- Create: `lib/features/categories/domain/models/category_model.dart`
- Create: `lib/features/categories/data/dtos/category_dto.dart`
- Create: `lib/features/categories/data/datasources/category_remote_data_source.dart`
- Create: `lib/features/categories/data/repositories/category_repository.dart`
- Create: `lib/features/categories/application/services/category_service.dart`
- Create: `lib/features/categories/presentation/states/category_state.dart`
- Move:   `lib/features/categories/screen/category.dart` → `lib/features/categories/presentation/screens/category_screen.dart`
- Remove: `lib/features/categories/models/category_model.dart`, `lib/features/categories/providers/category_provider.dart`, `lib/features/categories/repositories/category_repository.dart`
- Modify (importer): `lib/features/transactions/screens/widgets/transaction_form_sheet.dart` (2 import lines only)

**Interfaces:**
- Produces:
  - `CategoryModel` (pure) at `domain/models/category_model.dart` — fields `id:int, name:String, color:String?, type:String`; getters `isIncome`, `isExpense`.
  - `categoriesProvider`, `expenseCategoriesProvider`, `incomeCategoriesProvider` (`FutureProvider<List<CategoryModel>>`) at `presentation/states/category_state.dart`.
  - `categoryServiceProvider`, `categoryRepositoryProvider`, `categoryRemoteDataSourceProvider`.

- [ ] **Step 1: Create the pure domain model**

Create `lib/features/categories/domain/models/category_model.dart`:
```dart
/// A spending/income category — pure domain entity. No JSON.
class CategoryModel {
  final int id;
  final String name;
  final String? color;
  final String type; // "income" | "expense"

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

- [ ] **Step 2: Create the DTO**

Create `lib/features/categories/data/dtos/category_dto.dart`:
```dart
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Wire representation of a category. Owns JSON parsing so the domain model
/// stays pure.
class CategoryDto {
  final int id;
  final String name;
  final String? color;
  final String type;

  const CategoryDto({
    required this.id,
    required this.name,
    this.color,
    required this.type,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => CategoryDto(
        id: json['id'] as int,
        name: json['name'] as String,
        color: json['color'] as String?,
        type: json['type'] as String,
      );

  CategoryModel toDomain() =>
      CategoryModel(id: id, name: name, color: color, type: type);
}
```

- [ ] **Step 3: Create the data source**

Create `lib/features/categories/data/datasources/category_remote_data_source.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/categories/data/dtos/category_dto.dart';

/// Raw transport for categories. Unwraps the `"data"` envelope and returns
/// DTOs. Throws [DioException] on failure (mapped to Failure by the repo).
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CategoryDto>> getAll() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final list = response.data['data'] as List;
    return list
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryDto>> seed() async {
    final response = await _dio.post(ApiEndpoints.categoriesSeed);
    final list = response.data['data'] as List;
    return list
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>(
  (ref) => CategoryRemoteDataSource(ref.watch(dioProvider)),
);
```

- [ ] **Step 4: Create the repository**

Create `lib/features/categories/data/repositories/category_repository.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Maps category DTOs → domain models and converts transport errors.
class CategoryRepository {
  CategoryRepository(this._remote);

  final CategoryRemoteDataSource _remote;

  Future<List<CategoryModel>> getAll() async {
    try {
      final dtos = await _remote.getAll();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<List<CategoryModel>> seed() async {
    try {
      final dtos = await _remote.seed();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(categoryRemoteDataSourceProvider)),
);
```

- [ ] **Step 5: Create the service**

Create `lib/features/categories/application/services/category_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/data/repositories/category_repository.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Business logic for categories.
class CategoryService {
  CategoryService(this._repo);

  final CategoryRepository _repo;

  Future<List<CategoryModel>> list() => _repo.getAll();
  Future<List<CategoryModel>> seed() => _repo.seed();
}

final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(categoryRepositoryProvider)),
);
```

> No `CategoryController` is created: categories have no user-driven write actions wired to UI (seed is unused by screens). Adding an empty controller would be boilerplate with nothing to orchestrate (YAGNI within the chosen architecture).

- [ ] **Step 6: Create the states**

Create `lib/features/categories/presentation/states/category_state.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/application/services/category_service.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// All categories. Read by the transaction form.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryServiceProvider).list();
});

/// Only expense categories — convenience for filtered pickers.
final expenseCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isExpense).toList();
});

/// Only income categories.
final incomeCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isIncome).toList();
});
```

- [ ] **Step 7: Move the screen**

Run:
```bash
git mv "lib/features/categories/screen/category.dart" "lib/features/categories/presentation/screens/category_screen.dart"
```
The file content needs no edits (it only imports `package:flutter/material.dart` and defines `CategoryScreen` — a `Placeholder`). It has no importers.

- [ ] **Step 8: Remove the old category files**

Run:
```bash
git rm "lib/features/categories/models/category_model.dart" \
       "lib/features/categories/providers/category_provider.dart" \
       "lib/features/categories/repositories/category_repository.dart"
```

- [ ] **Step 9: Fix the one importer (transaction form sheet)**

In `lib/features/transactions/screens/widgets/transaction_form_sheet.dart`, replace these two import lines:
```dart
import '../../../categories/models/category_model.dart';
import '../../../categories/providers/category_provider.dart';
```
with:
```dart
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
```
(Leave every other import and all code in that file unchanged for now — it moves in Task 2.)

- [ ] **Step 10: Analyze, test, commit**

Run:
```bash
flutter analyze
flutter test
git add -A
git commit -m "refactor(categories): migrate to clean architecture layers"
```
Expected: analyze shows no NEW issues vs. baseline; test PASSES.

---

## Task 2: Migrate `transactions`

**Files:**
- Create: `lib/features/transactions/domain/models/transaction_model.dart`
- Create: `lib/features/transactions/domain/models/transaction_filter.dart`
- Create: `lib/features/transactions/data/dtos/transaction_dto.dart`
- Create: `lib/features/transactions/data/datasources/transaction_remote_data_source.dart`
- Create: `lib/features/transactions/data/repositories/transaction_repository.dart`
- Create: `lib/features/transactions/application/services/transaction_service.dart`
- Create: `lib/features/transactions/presentation/states/transaction_state.dart`
- Create: `lib/features/transactions/presentation/controllers/transaction_controller.dart`
- Move:   `screens/transaction_screen.dart` → `presentation/screens/transaction_screen.dart`
- Move:   `screens/widgets/{transaction_form_sheet,transaction_list_item,transaction_type_filter}.dart` → `presentation/screens/widgets/`
- Remove: old `models/transaction_model.dart`, `models/transaction_filter.dart`, `repositories/transaction_repository.dart`, `providers/transaction_provider.dart`
- Modify (importers): `lib/features/auth/providers/auth_provider.dart` (1 import line), `lib/core/router/app_router.dart` (1 import line)

**Interfaces:**
- Consumes: `Failure`/`FailureType` (`core/error/failure.dart`); `dioProvider` (`core/api/api_client.dart`); category states from Task 1.
- Produces:
  - `TransactionModel` (pure) at `domain/models/transaction_model.dart`.
  - `TransactionFilter` (pure; `copyWith`, `==`/`hashCode`; **no** `toQueryParameters`) at `domain/models/transaction_filter.dart`.
  - `transactionsProvider` (`FutureProvider<List<TransactionModel>>`), `transactionFilterProvider` (`StateProvider<TransactionFilter>`) at `presentation/states/transaction_state.dart`.
  - `transactionControllerProvider` → `TransactionController` with `create({...})`, `update({...})`, `delete(int)` at `presentation/controllers/transaction_controller.dart`.

- [ ] **Step 1: Create the pure domain model**

Create `lib/features/transactions/domain/models/transaction_model.dart`:
```dart
/// A single transaction — pure domain entity. No JSON, no Dio.
class TransactionModel {
  final int id;
  final String transactionDate;
  final String transactionType; // "income" | "expense"
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor; // hex "#RRGGBB"
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

- [ ] **Step 2: Create the pure filter value object**

Create `lib/features/transactions/domain/models/transaction_filter.dart`:
```dart
/// Immutable filter criteria for the transactions list. Pure domain — the
/// data source translates this into query parameters.
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
```

- [ ] **Step 3: Create the DTO**

Create `lib/features/transactions/data/dtos/transaction_dto.dart`:
```dart
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Wire representation of a transaction. Owns all JSON so the domain model
/// stays pure. The API returns camelCase but accepts snake_case on write.
class TransactionDto {
  final int id;
  final String transactionDate;
  final String transactionType;
  final double amount;
  final int? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryColor;
  final String? createdAt;
  final String? updatedAt;

  const TransactionDto({
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

  factory TransactionDto.fromJson(Map<String, dynamic> json) => TransactionDto(
        id: json['id'] as int,
        transactionDate: json['transactionDate'] as String,
        transactionType: json['transactionType'] as String,
        amount: (json['amount'] as num).toDouble(),
        categoryId: json['categoryId'] as int?,
        description: json['description'] as String?,
        categoryName: json['categoryName'] as String?,
        categoryColor: json['categoryColor'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
      );

  factory TransactionDto.fromDomain(TransactionModel m) => TransactionDto(
        id: m.id,
        transactionDate: m.transactionDate,
        transactionType: m.transactionType,
        amount: m.amount,
        categoryId: m.categoryId,
        description: m.description,
        categoryName: m.categoryName,
        categoryColor: m.categoryColor,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  /// Write payload (snake_case). Only fields the API accepts on write.
  Map<String, dynamic> toJson() => {
        'transaction_date': transactionDate,
        'transaction_type': transactionType,
        'amount': amount,
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
      };

  TransactionModel toDomain() => TransactionModel(
        id: id,
        transactionDate: transactionDate,
        transactionType: transactionType,
        amount: amount,
        categoryId: categoryId,
        description: description,
        categoryName: categoryName,
        categoryColor: categoryColor,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
```

- [ ] **Step 4: Create the data source**

Create `lib/features/transactions/data/datasources/transaction_remote_data_source.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

/// Raw transport for transactions. Talks to Dio, unwraps the `"data"`
/// envelope, builds query params from the filter, and returns DTOs. Throws
/// [DioException] on failure (mapped to Failure by the repository).
class TransactionRemoteDataSource {
  TransactionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TransactionDto>> getAll(TransactionFilter filter) async {
    final response = await _dio.get(
      ApiEndpoints.transactions,
      queryParameters: _queryFrom(filter),
    );
    final list = response.data['data'] as List;
    return list
        .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionDto> create(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiEndpoints.transactions, data: body);
    return TransactionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<TransactionDto> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put(
      ApiEndpoints.transactionById(id),
      data: body,
    );
    return TransactionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.transactionById(id));
  }

  Map<String, dynamic> _queryFrom(TransactionFilter f) => {
        if (f.salaryPeriodId != null) 'salary_period_id': f.salaryPeriodId,
        if (f.filter != null) 'filter': f.filter,
        if (f.startDate != null) 'start_date': f.startDate,
        if (f.endDate != null) 'end_date': f.endDate,
        if (f.transactionType != null) 'transaction_type': f.transactionType,
        'page': f.page,
        'limit': f.limit,
      };
}

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>(
  (ref) => TransactionRemoteDataSource(ref.watch(dioProvider)),
);
```

- [ ] **Step 5: Create the repository**

Create `lib/features/transactions/data/repositories/transaction_repository.dart`:
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Maps DTOs ⇄ domain models and converts [DioException] into [Failure].
/// Never touches Dio directly — that's the data source's job.
class TransactionRepository {
  TransactionRepository(this._remote);

  final TransactionRemoteDataSource _remote;

  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    try {
      final dtos = await _remote.getAll(filter);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final dto = await _remote.create(
        TransactionDto.fromDomain(transaction).toJson(),
      );
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<TransactionModel> update(TransactionModel transaction) async {
    try {
      final dto = await _remote.update(
        transaction.id,
        TransactionDto.fromDomain(transaction).toJson(),
      );
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) =>
      TransactionRepository(ref.watch(transactionRemoteDataSourceProvider)),
);
```

- [ ] **Step 6: Create the service**

Create `lib/features/transactions/application/services/transaction_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/data/repositories/transaction_repository.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Business logic for transactions. Builds domain objects from raw inputs and
/// orchestrates the repository. No Riverpod state, no widgets.
class TransactionService {
  TransactionService(this._repo);

  final TransactionRepository _repo;

  Future<List<TransactionModel>> list(TransactionFilter filter) =>
      _repo.getAll(filter);

  Future<TransactionModel> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    final transaction = TransactionModel(
      id: 0,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    return _repo.create(transaction);
  }

  Future<TransactionModel> update({
    required int id,
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) {
    final transaction = TransactionModel(
      id: id,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    return _repo.update(transaction);
  }

  Future<void> delete(int id) => _repo.delete(id);
}

final transactionServiceProvider = Provider<TransactionService>(
  (ref) => TransactionService(ref.watch(transactionRepositoryProvider)),
);
```

- [ ] **Step 7: Create the states**

Create `lib/features/transactions/presentation/states/transaction_state.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

/// Current list filter. Mutating this re-runs [transactionsProvider].
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

/// The filtered transaction list — the screen's primary read.
final transactionsProvider = FutureProvider<List<TransactionModel>>((ref) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transactionServiceProvider).list(filter);
});
```

- [ ] **Step 8: Create the controller**

Create `lib/features/transactions/presentation/controllers/transaction_controller.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/transactions/application/services/transaction_service.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

/// Riverpod glue for writes. Delegates business logic to [TransactionService]
/// and refreshes the list afterwards. Screens call this; it holds no UI.
class TransactionController {
  TransactionController(this._ref, this._service);

  final Ref _ref;
  final TransactionService _service;

  Future<TransactionModel> create({
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) async {
    final created = await _service.create(
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    _ref.invalidate(transactionsProvider);
    return created;
  }

  Future<TransactionModel> update({
    required int id,
    required String transactionDate,
    required String transactionType,
    required double amount,
    int? categoryId,
    String? description,
  }) async {
    final updated = await _service.update(
      id: id,
      transactionDate: transactionDate,
      transactionType: transactionType,
      amount: amount,
      categoryId: categoryId,
      description: description,
    );
    _ref.invalidate(transactionsProvider);
    return updated;
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _ref.invalidate(transactionsProvider);
  }
}

final transactionControllerProvider = Provider<TransactionController>(
  (ref) => TransactionController(ref, ref.watch(transactionServiceProvider)),
);
```

- [ ] **Step 9: Move the screen + widgets**

Run:
```bash
git mv "lib/features/transactions/screens/transaction_screen.dart" "lib/features/transactions/presentation/screens/transaction_screen.dart"
git mv "lib/features/transactions/screens/widgets/transaction_form_sheet.dart" "lib/features/transactions/presentation/screens/widgets/transaction_form_sheet.dart"
git mv "lib/features/transactions/screens/widgets/transaction_list_item.dart" "lib/features/transactions/presentation/screens/widgets/transaction_list_item.dart"
git mv "lib/features/transactions/screens/widgets/transaction_type_filter.dart" "lib/features/transactions/presentation/screens/widgets/transaction_type_filter.dart"
```

- [ ] **Step 10: Fix imports in `transaction_screen.dart`**

In `lib/features/transactions/presentation/screens/transaction_screen.dart`, replace the entire import block (all lines from the first `import` to the last `import`) with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/router/app_router.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_form_sheet.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_list_item.dart';
import 'package:pixel_pocket/features/transactions/presentation/screens/widgets/transaction_type_filter.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
import 'package:pixelarticons/pixel.dart';
```
> The `auth_provider.dart` import deliberately points at the OLD auth location — Task 4 updates it. Do not change any code below the imports (the `final router = GoRouter.of(context);` line stays as-is to preserve current analyzer baseline).

- [ ] **Step 11: Fix imports in `transaction_form_sheet.dart`**

In `lib/features/transactions/presentation/screens/widgets/transaction_form_sheet.dart`, replace the entire import block with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
import 'package:pixel_pocket/features/transactions/presentation/controllers/transaction_controller.dart';
```

- [ ] **Step 12: Fix imports in `transaction_list_item.dart`**

In `lib/features/transactions/presentation/screens/widgets/transaction_list_item.dart`, replace the entire import block with:
```dart
import 'package:flutter/material.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/utils/currency_formatter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';
```

- [ ] **Step 13: Fix imports in `transaction_type_filter.dart`**

In `lib/features/transactions/presentation/screens/widgets/transaction_type_filter.dart`, replace the entire import block with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
```

- [ ] **Step 14: Remove old transaction files**

Run:
```bash
git rm "lib/features/transactions/models/transaction_model.dart" \
       "lib/features/transactions/models/transaction_filter.dart" \
       "lib/features/transactions/repositories/transaction_repository.dart" \
       "lib/features/transactions/providers/transaction_provider.dart"
```

- [ ] **Step 15: Fix the two external importers**

In `lib/features/auth/providers/auth_provider.dart`, replace:
```dart
import '../../transactions/providers/transaction_provider.dart';
```
with:
```dart
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';
```

In `lib/core/router/app_router.dart`, replace:
```dart
import 'package:pixel_pocket/features/transactions/screens/transaction_screen.dart';
```
with:
```dart
import 'package:pixel_pocket/features/transactions/presentation/screens/transaction_screen.dart';
```

- [ ] **Step 16: Analyze, test, commit**

Run:
```bash
flutter analyze
flutter test
git add -A
git commit -m "refactor(transactions): migrate to clean architecture layers"
```
Expected: no new analyzer issues; test PASSES.

---

## Task 3: Migrate `dashboard`

**Files:**
- Create: `lib/features/dashboard/domain/models/transaction_summary.dart`
- Create: `lib/features/dashboard/data/dtos/summary_dto.dart`
- Create: `lib/features/dashboard/data/datasources/dashboard_remote_data_source.dart`
- Create: `lib/features/dashboard/data/repositories/dashboard_repository.dart`
- Create: `lib/features/dashboard/application/services/dashboard_service.dart`
- Create: `lib/features/dashboard/presentation/states/dashboard_state.dart`
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart` (full rewrite — async + import fixes), then `git mv` into `presentation/screens/`
- Move:   `presentation/widgets/{period_filter_card,transaction_summary_card}.dart` → `presentation/screens/widgets/`
- Modify: `transaction_summary_card.dart` (1 import line)
- Remove: old `model/transaction_summary.dart`, `model/summary_dummy.dart`, `provider/dashboard_provider.dart` (empty), `repositories/dashboard_repository.dart` (empty)
- Modify (importer): `lib/core/router/app_router.dart` (1 import line)

**Interfaces:**
- Produces:
  - `TransactionSummary` (pure; getters `spentPercentage`, `spentPercentageString`) at `domain/models/transaction_summary.dart`.
  - `dashboardSummaryProvider` (`FutureProvider<TransactionSummary>`) at `presentation/states/dashboard_state.dart`.

> The dashboard currently renders hardcoded dummy values synchronously. To match the rest of the app it now flows through layers and the screen consumes a `FutureProvider` with `.when`. Wiring the real `GET /api/summary` is out of scope; the data source returns stub values.

- [ ] **Step 1: Create the pure domain model**

Create `lib/features/dashboard/domain/models/transaction_summary.dart`:
```dart
/// Aggregated totals for the dashboard. Pure domain — no JSON.
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

  double get spentPercentage {
    if (totalIncome <= 0) return 0;
    return totalExpense / totalIncome;
  }

  String get spentPercentageString =>
      '${(spentPercentage * 100).toStringAsFixed(0)}%';
}
```

- [ ] **Step 2: Create the DTO**

Create `lib/features/dashboard/data/dtos/summary_dto.dart`:
```dart
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Wire representation of the summary endpoint (`GET /api/summary`).
class SummaryDto {
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int transactionCount;

  const SummaryDto({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.transactionCount,
  });

  factory SummaryDto.fromJson(Map<String, dynamic> json) => SummaryDto(
        totalIncome: (json['total_income'] as num).toDouble(),
        totalExpense: (json['total_expense'] as num).toDouble(),
        balance: (json['balance'] as num).toDouble(),
        transactionCount: json['transaction_count'] as int,
      );

  TransactionSummary toDomain() => TransactionSummary(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        balance: balance,
        transactionCount: transactionCount,
      );
}
```

- [ ] **Step 3: Create the data source (stub)**

Create `lib/features/dashboard/data/datasources/dashboard_remote_data_source.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/dtos/summary_dto.dart';

/// Source of dashboard summary data. Returns stub values for now; wiring the
/// real `GET /api/summary` endpoint is out of scope for this migration.
class DashboardRemoteDataSource {
  Future<SummaryDto> getSummary() async => const SummaryDto(
        totalIncome: 10000000,
        totalExpense: 5000000,
        balance: 5000000,
        transactionCount: 10,
      );
}

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(),
);
```

- [ ] **Step 4: Create the repository**

Create `lib/features/dashboard/data/repositories/dashboard_repository.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/datasources/dashboard_remote_data_source.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Maps the summary DTO to the domain model.
class DashboardRepository {
  DashboardRepository(this._remote);

  final DashboardRemoteDataSource _remote;

  Future<TransactionSummary> getSummary() async {
    final dto = await _remote.getSummary();
    return dto.toDomain();
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.watch(dashboardRemoteDataSourceProvider)),
);
```

- [ ] **Step 5: Create the service**

Create `lib/features/dashboard/application/services/dashboard_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

/// Business logic for the dashboard.
class DashboardService {
  DashboardService(this._repo);

  final DashboardRepository _repo;

  Future<TransactionSummary> summary() => _repo.getSummary();
}

final dashboardServiceProvider = Provider<DashboardService>(
  (ref) => DashboardService(ref.watch(dashboardRepositoryProvider)),
);
```

- [ ] **Step 6: Create the state**

Create `lib/features/dashboard/presentation/states/dashboard_state.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

final dashboardSummaryProvider = FutureProvider<TransactionSummary>(
  (ref) => ref.watch(dashboardServiceProvider).summary(),
);
```

- [ ] **Step 7: Move dashboard widgets**

Run:
```bash
git mv "lib/features/dashboard/presentation/widgets/period_filter_card.dart" "lib/features/dashboard/presentation/screens/widgets/period_filter_card.dart"
git mv "lib/features/dashboard/presentation/widgets/transaction_summary_card.dart" "lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart"
```
`period_filter_card.dart` only imports core theme (all `package:pixel_pocket/core/theme/...`) — no edits needed.

- [ ] **Step 8: Fix import in `transaction_summary_card.dart`**

In `lib/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart`, replace:
```dart
import 'package:pixel_pocket/features/dashboard/model/transaction_summary.dart';
```
with:
```dart
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';
```
(All other imports in that file are already `package:pixel_pocket/core/...` and stay.)

- [ ] **Step 9: Rewrite + move the dashboard screen**

Run:
```bash
git mv "lib/features/dashboard/presentation/dashboard_screen.dart" "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
```
Then replace the ENTIRE contents of `lib/features/dashboard/presentation/screens/dashboard_screen.dart` with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/theme/app_text_style.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
import 'package:pixel_pocket/features/dashboard/presentation/states/dashboard_state.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/period_filter_card.dart';
import 'package:pixel_pocket/features/dashboard/presentation/screens/widgets/transaction_summary_card.dart';
import 'package:pixelarticons/pixel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    return SafeArea(
      child: Scaffold(
        body: summaryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (summary) => Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.section),
            child: Column(
              children: [
                Padding(
                  padding: AppSpacing.card,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '~\$ Pixel-Pocket',
                        style: AppTextStyles.displayMedium,
                      ),
                      PixelButton(
                        onPressed: () =>
                            ref.read(authControllerProvider.notifier).logout(),
                        variant: PixelButtonVariant.danger,
                        icon: Pixel.logout,
                        size: PixelButtonSize.sm,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.section),
                const PeriodFilterCard(),
                SizedBox(height: AppSpacing.section),
                Padding(
                  padding: AppSpacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TransactionSummaryCard(summary: summary),
                      SizedBox(height: AppSpacing.section),
                      Text(
                        'EXPENSES BY CATEGORY',
                        style: AppTextStyles.bodyNormal,
                      ),
                      SizedBox(height: AppSpacing.section),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```
> The `auth_provider.dart` import points at the OLD auth location — Task 4 updates it.

- [ ] **Step 10: Remove old dashboard files**

Run:
```bash
git rm "lib/features/dashboard/model/transaction_summary.dart" \
       "lib/features/dashboard/model/summary_dummy.dart" \
       "lib/features/dashboard/provider/dashboard_provider.dart" \
       "lib/features/dashboard/repositories/dashboard_repository.dart"
```

- [ ] **Step 11: Fix the router importer**

In `lib/core/router/app_router.dart`, replace:
```dart
import 'package:pixel_pocket/features/dashboard/presentation/dashboard_screen.dart';
```
with:
```dart
import 'package:pixel_pocket/features/dashboard/presentation/screens/dashboard_screen.dart';
```

- [ ] **Step 12: Analyze, test, commit**

Run:
```bash
flutter analyze
flutter test
git add -A
git commit -m "refactor(dashboard): migrate to clean architecture layers"
```
Expected: no new analyzer issues; test PASSES.

---

## Task 4: Migrate `auth` + fix all auth importers

**Files:**
- Create: `lib/features/auth/data/datasources/auth_remote_data_source.dart` (the SDK wrapper, from the old repo)
- Create: `lib/features/auth/data/repositories/auth_repository.dart` (thin delegate + `authRepositoryProvider`)
- Create: `lib/features/auth/application/services/auth_service.dart`
- Create: `lib/features/auth/presentation/states/auth_state.dart` (the `AuthState` sealed hierarchy)
- Create: `lib/features/auth/presentation/controllers/auth_controller.dart` (`AuthController` + `authControllerProvider`)
- Move:   `screens/login_screen.dart` → `presentation/screens/login_screen.dart`; `screens/splash_screen.dart` → `presentation/screens/splash_screen.dart`
- Keep:   `lib/features/auth/auth_config.dart` (feature-root config)
- Remove: old `providers/auth_provider.dart`, `repositories/auth_repository.dart`
- Modify (importers): `lib/core/api/auth_interceptor.dart`, `lib/core/router/app_router.dart`, `lib/features/transactions/presentation/screens/transaction_screen.dart`, `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, `test/widget_test.dart`, `lib/features/auth/presentation/screens/login_screen.dart`

**Interfaces:**
- Consumes: `transactionsProvider` (Task 2) for logout invalidation; `GoogleSignIn` SDK via `AuthConfig`.
- Produces:
  - `AuthState` sealed hierarchy: `AuthUnknown`, `AuthSignedOut`, `AuthSignedIn(GoogleSignInAccount account)` at `presentation/states/auth_state.dart`.
  - `AuthController extends Notifier<AuthState>` with `login()`, `logout()`; `authControllerProvider` at `presentation/controllers/auth_controller.dart`.
  - `authRepositoryProvider` → `AuthRepository` with `initialize()`, `authEvents`, `lightweightAuthentication()`, `signIn()`, `signOut()`, `currentIdToken()` at `data/repositories/auth_repository.dart`.

- [ ] **Step 1: Create the data source (SDK wrapper)**

Create `lib/features/auth/data/datasources/auth_remote_data_source.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/auth_config.dart';

/// Thin wrapper over the `google_sign_in` v7 SDK. No widgets, no Riverpod
/// state — just the auth operations the rest of the app needs.
///
/// In v7 the source of truth for sign-in changes is [authEvents]; the
/// controller listens to it. Token retrieval re-reads the active account so
/// it always returns the freshest available ID token.
class AuthRemoteDataSource {
  final GoogleSignIn _google = GoogleSignIn.instance;
  bool _initialized = false;

  /// Stream of sign-in / sign-out events emitted by the SDK.
  Stream<GoogleSignInAuthenticationEvent> get authEvents =>
      _google.authenticationEvents;

  /// Must be called once before any other method.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _google.initialize(
        serverClientId: AuthConfig.serverClientId,
        clientId: AuthConfig.iosClientId,
      );
    } catch (_) {
      // Native SDK bisa SUDAH ter-inisialisasi (umum setelah hot restart,
      // karena singleton native bertahan walau state Dart direset). Aman
      // diabaikan — sesi tetap bisa dipulihkan lewat lightweight auth.
    }
    _initialized = true;
  }

  /// Non-interactive restore of a previous session. Returns the account when
  /// one is available, otherwise null.
  Future<GoogleSignInAccount?> lightweightAuthentication() async {
    final attempt = _google.attemptLightweightAuthentication();
    return attempt == null ? null : await attempt;
  }

  /// Interactive sign-in (shows the Google account picker).
  /// Returns the account, or null when the user cancels the picker.
  Future<GoogleSignInAccount?> signIn() async {
    if (!_google.supportsAuthenticate()) {
      throw UnsupportedError('authenticate() tidak didukung di platform ini');
    }
    try {
      return await _google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow; // kegagalan nyata tetap dilempar
    }
  }

  Future<void> signOut() => _google.signOut();

  /// Fetches a fresh ID token from the active session, or null if signed out.
  Future<String?> currentIdToken() async {
    final account = await lightweightAuthentication();
    return account?.authentication.idToken;
  }
}

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(),
);
```

- [ ] **Step 2: Create the repository (delegate)**

Create `lib/features/auth/data/repositories/auth_repository.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';

/// Auth data-layer API. Delegates to [AuthRemoteDataSource]; exists so higher
/// layers depend on a repository rather than the SDK wrapper directly.
class AuthRepository {
  AuthRepository(this._remote);

  final AuthRemoteDataSource _remote;

  Stream<GoogleSignInAuthenticationEvent> get authEvents => _remote.authEvents;

  Future<void> initialize() => _remote.initialize();

  Future<GoogleSignInAccount?> lightweightAuthentication() =>
      _remote.lightweightAuthentication();

  Future<GoogleSignInAccount?> signIn() => _remote.signIn();

  Future<void> signOut() => _remote.signOut();

  Future<String?> currentIdToken() => _remote.currentIdToken();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authRemoteDataSourceProvider)),
);
```

- [ ] **Step 3: Create the service**

Create `lib/features/auth/application/services/auth_service.dart`:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_repository.dart';

/// Business logic for authentication. Thin orchestration over the repository;
/// keeps the controller free of data-layer details.
class AuthService {
  AuthService(this._repo);

  final AuthRepository _repo;

  Stream<GoogleSignInAuthenticationEvent> get authEvents => _repo.authEvents;

  Future<void> initialize() => _repo.initialize();

  Future<GoogleSignInAccount?> lightweightAuthentication() =>
      _repo.lightweightAuthentication();

  Future<GoogleSignInAccount?> signIn() => _repo.signIn();

  Future<void> signOut() => _repo.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authRepositoryProvider)),
);
```

- [ ] **Step 4: Create the auth state**

Create `lib/features/auth/presentation/states/auth_state.dart`:
```dart
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication state. [AuthUnknown] is the launch state — the router keeps
/// the user on the splash screen until it resolves, avoiding a flicker to the
/// login screen while the silent sign-in is still running.
sealed class AuthState {
  const AuthState();
}

class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.account);
  final GoogleSignInAccount account;
}
```

- [ ] **Step 5: Create the controller**

Create `lib/features/auth/presentation/controllers/auth_controller.dart`:
```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/application/services/auth_service.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
import 'package:pixel_pocket/features/transactions/presentation/states/transaction_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Owns the auth lifecycle: bootstraps a silent sign-in on launch, mirrors
/// SDK events into [AuthState], and exposes login/logout.
class AuthController extends Notifier<AuthState> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _sub;

  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    ref.onDispose(() => _sub?.cancel());
    _bootstrap();
    return const AuthUnknown();
  }

  Future<void> _bootstrap() async {
    try {
      await _service.initialize();
      _sub = _service.authEvents.listen(_onEvent);
      final account = await _service.lightweightAuthentication();
      if (account != null) {
        state = AuthSignedIn(account);
      } else if (state is AuthUnknown) {
        state = const AuthSignedOut();
      }
    } catch (_) {
      // SDK belum tersedia / init gagal → tampilkan login, jangan crash.
      if (state is AuthUnknown) state = const AuthSignedOut();
    }
  }

  void _onEvent(GoogleSignInAuthenticationEvent event) {
    switch (event) {
      case GoogleSignInAuthenticationEventSignIn(:final user):
        state = AuthSignedIn(user);
      case GoogleSignInAuthenticationEventSignOut():
        state = const AuthSignedOut();
    }
  }

  Future<void> login() async {
    final account = await _service.signIn();
    // account == null → user batal: biarkan tetap signed-out, bukan error.
    if (account != null) state = AuthSignedIn(account);
  }

  Future<void> logout() async {
    await _service.signOut();
    state = const AuthSignedOut();
    ref.invalidate(transactionsProvider); // drop the previous user's data
  }
}
```

- [ ] **Step 6: Move login + splash screens**

Run:
```bash
git mv "lib/features/auth/screens/login_screen.dart" "lib/features/auth/presentation/screens/login_screen.dart"
git mv "lib/features/auth/screens/splash_screen.dart" "lib/features/auth/presentation/screens/splash_screen.dart"
```
`splash_screen.dart` only imports `package:flutter/material.dart` — no edits.

- [ ] **Step 7: Fix imports in `login_screen.dart`**

In `lib/features/auth/presentation/screens/login_screen.dart`, replace the entire import block with:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/theme/app_color.dart';
import 'package:pixel_pocket/core/theme/app_spacing.dart';
import 'package:pixel_pocket/core/widgets/pixel_button.dart';
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixelarticons/pixel.dart';
```

- [ ] **Step 8: Remove old auth files**

Run:
```bash
git rm "lib/features/auth/providers/auth_provider.dart" \
       "lib/features/auth/repositories/auth_repository.dart"
```

- [ ] **Step 9: Fix the auth interceptor**

In `lib/core/api/auth_interceptor.dart`, replace:
```dart
import '../../features/auth/providers/auth_provider.dart';
```
with:
```dart
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/states/auth_state.dart';
```
(All code in the file stays the same — it references `authControllerProvider`, `authRepositoryProvider`, `AuthSignedIn`, all now imported from the new locations.)

- [ ] **Step 10: Fix the router**

In `lib/core/router/app_router.dart`, replace these three lines:
```dart
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
```
with:
```dart
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/states/auth_state.dart';
```

- [ ] **Step 11: Fix the auth import in `transaction_screen.dart`**

In `lib/features/transactions/presentation/screens/transaction_screen.dart`, replace:
```dart
import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
```
with:
```dart
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
```

- [ ] **Step 12: Fix the auth import in `dashboard_screen.dart`**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, replace:
```dart
import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
```
with:
```dart
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
```

- [ ] **Step 13: Fix the widget test**

In `test/widget_test.dart`, replace:
```dart
import 'package:pixel_pocket/features/auth/providers/auth_provider.dart';
```
with:
```dart
import 'package:pixel_pocket/features/auth/presentation/controllers/auth_controller.dart';
import 'package:pixel_pocket/features/auth/presentation/states/auth_state.dart';
```
(The test's `_SignedOutAuthController extends AuthController` and `authControllerProvider.overrideWith(...)` keep working unchanged.)

- [ ] **Step 14: Analyze, test, commit**

Run:
```bash
flutter analyze
flutter test
git add -A
git commit -m "refactor(auth): migrate to clean architecture layers and rewire importers"
```
Expected: no new analyzer issues; the smoke test still PASSES (gates to login).

---

## Task 5: Update CLAUDE.md + clean up empty dirs + final verification

**Files:**
- Modify: `CLAUDE.md`
- Remove (on disk): now-empty old feature directories

- [ ] **Step 1: Update the architecture sections of CLAUDE.md**

In `CLAUDE.md`, replace the `## Arsitektur` section's folder block and the `### Aturan ketat` table so they describe the new layers. Specifically:

Replace the old per-feature tree:
```
features/<feature>/
├── models/          ← fromJson / toJson saja
├── repositories/    ← semua API call & logic
├── providers/       ← state saja, panggil repository
└── screens/         ← UI only, tidak ada logic
    └── widgets/
```
with:
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

Replace the `### Aturan ketat` table with:
```
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
```

Then update the `## Pola Kode` examples (`### Repository`, `### Provider`, `### Screen`) so their import paths and class wiring reflect the new structure (e.g. `Repository` depends on a `RemoteDataSource`, `transactionsProvider` lives in `presentation/states/`, the screen reads `transactionServiceProvider` via the state). Keep the examples short and consistent with the code created in Tasks 1–4.

- [ ] **Step 2: Remove empty leftover directories**

Run:
```bash
find lib/features -type d -empty -delete
```
Expected: removes now-empty old dirs (`models`, `providers`, `repositories`, `screens`, `screen`, `model`, `provider`, old `presentation/widgets`, etc.). `git status` should show no tracked deletions here (git doesn't track empty dirs).

- [ ] **Step 3: Verify the final structure**

Run:
```bash
find lib/features -type f -name "*.dart" | sort
```
Expected: every feature shows `data/`, `domain/`, `application/`, `presentation/` subtrees and NO old `models/` `providers/` `repositories/` `screens/` `screen/` `model/` `provider/` folders.

- [ ] **Step 4: Final analyze + test**

Run:
```bash
flutter analyze
flutter test
```
Expected: no new analyzer issues vs. the Pre-flight baseline; smoke test PASSES.

- [ ] **Step 5: Commit**

Run:
```bash
git add -A
git commit -m "docs: update CLAUDE.md for clean architecture + remove empty dirs"
```

---

## Self-Review (completed during planning)

- **Spec coverage:** All four diagram layers are produced per feature (Tasks 1–4); Services added; DTOs separated; DataSources added; domain models made pure. CLAUDE.md updated (Task 5). Auth special-case (no DTO, SDK data source) handled (Task 4). Dashboard dummy → data source (Task 3). Verification gates in every task. ✓
- **Placeholder scan:** No "TBD"/"TODO"/"similar to" — every file shows full code or exact import replacements. The only "out of scope" note (real `GET /api/summary`) is an intentional spec boundary, not a plan gap. ✓
- **Type consistency:** `transactionsProvider`/`transactionFilterProvider` (states), `transactionControllerProvider` (controller), `transactionServiceProvider`/`transactionRepositoryProvider`/`transactionRemoteDataSourceProvider`, `categoriesProvider`/`expenseCategoriesProvider`/`incomeCategoriesProvider`, `dashboardSummaryProvider`, `authControllerProvider`/`authRepositoryProvider`/`authServiceProvider`/`authRemoteDataSourceProvider`, and `AuthState`/`AuthUnknown`/`AuthSignedOut`/`AuthSignedIn` are referenced consistently across producing and consuming tasks. ✓
