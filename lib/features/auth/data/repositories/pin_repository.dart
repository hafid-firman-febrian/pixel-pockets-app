import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/data/datasources/pin_local_data_source.dart';

/// Data-layer gateway for the local PIN credential. Thin pass-through over
/// [PinLocalDataSource] — keeps the service free of the storage detail and is
/// the seam the service is tested against.
class PinRepository {
  PinRepository(this._local);

  final PinLocalDataSource _local;

  Future<bool> hasPin() => _local.hasPin();

  Future<void> save({required String hash, required String salt}) =>
      _local.save(hash: hash, salt: salt);

  Future<({String hash, String salt})?> read() => _local.read();

  Future<void> clear() => _local.clear();
}

final pinRepositoryProvider = Provider<PinRepository>(
  (ref) => PinRepository(ref.watch(pinLocalDataSourceProvider)),
);
