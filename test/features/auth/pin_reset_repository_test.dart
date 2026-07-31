import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/auth/data/datasources/pin_local_data_source.dart';
import 'package:pixel_pocket/features/auth/data/repositories/pin_reset_repository.dart';

/// In-memory stand-in for [PinLocalDataSource] so the repository is tested
/// without touching platform secure storage (same approach as
/// pin_service_test.dart's `_FakePinRepository`).
class _FakePinLocalDataSource implements PinLocalDataSource {
  ({String hash, String salt})? stored = (hash: 'h', salt: 's');

  @override
  Future<bool> hasPin() async => stored != null;

  @override
  Future<void> save({required String hash, required String salt}) async =>
      stored = (hash: hash, salt: salt);

  @override
  Future<({String hash, String salt})?> read() async => stored;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late AppDatabase db;
  late _FakePinLocalDataSource pinLocal;
  late PinResetRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    pinLocal = _FakePinLocalDataSource();
    repo = PinResetRepository(db: db, pinLocal: pinLocal);
  });
  tearDown(() => db.close());

  test('wipeAll clears local data and removes the stored PIN', () async {
    await db.seedDefaultCategoriesIfEmpty();
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            transactionDate: '2026-07-05',
            transactionType: 'expense',
            amount: 12,
          ),
        );

    await repo.wipeAll();

    expect(await db.select(db.transactions).get(), isEmpty);
    expect((await db.select(db.categories).get()).length, 18);
    expect(pinLocal.stored, isNull);
  });
}
