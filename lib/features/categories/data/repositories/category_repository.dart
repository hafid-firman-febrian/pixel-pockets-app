import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_local_data_source.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Maps category DTOs → domain models and converts transport errors.
class CategoryRepository {
  CategoryRepository(this._remote, this._local);

  final CategoryRemoteDataSource _remote;
  final CategoryLocalDataSource _local;

  Future<List<CategoryModel>> getAll() async {
    try {
      final dtos = await _remote.getAll();
      await _local.save(dtos);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.read();
        if (cached != null) return cached.map((d) => d.toDomain()).toList();
      }
      throw Failure.fromDio(e);
    }
  }

  Future<List<CategoryModel>> seed() async {
    try {
      final dtos = await _remote.seed();
      await _local.invalidate();
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<CategoryModel> create({
    required String name,
    required String color,
    required String type,
  }) async {
    try {
      final dto = await _remote.create(name: name, color: color, type: type);
      await _local.invalidate();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<CategoryModel> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) async {
    try {
      final dto = await _remote.update(
        id: id,
        name: name,
        color: color,
        type: type,
      );
      await _local.invalidate();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
      await _local.invalidate();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(
    ref.watch(categoryRemoteDataSourceProvider),
    ref.watch(categoryLocalDataSourceProvider),
  ),
);
