import 'package:get_it/get_it.dart';

import '../../features/products/data/datasources/product_remote_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/products/domain/usecases/get_categories.dart';
import '../../features/products/domain/usecases/get_products.dart';
import '../../features/products/presentation/manager/products_cubit.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

/// Registers all dependencies. Call once in `main()`.
Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));

  // Cubits
  sl.registerFactory(
    () => ProductsCubit(getProducts: sl(), getCategories: sl()),
  );
}
