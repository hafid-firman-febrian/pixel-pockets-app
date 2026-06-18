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
