import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/backup/application/import_service.dart';

class ImportController extends AutoDisposeAsyncNotifier<ImportResult?> {
  @override
  Future<ImportResult?> build() async => null;

  Future<void> run() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(importServiceProvider).importAll(),
    );
  }
}

final importControllerProvider =
    AutoDisposeAsyncNotifierProvider<ImportController, ImportResult?>(
      ImportController.new,
    );
