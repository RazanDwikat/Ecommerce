import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'features/products/presentation/manager/filter_cubit.dart';
import 'features/products/presentation/manager/products_cubit.dart';
import 'features/products/presentation/pages/products_page.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(const EcommerceApp());
}

class EcommerceApp extends StatelessWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProductsCubit>()),
        BlocProvider(create: (_) => FilterCubit()),
      ],
      child: MaterialApp(
        title: 'Ecommerce',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const ProductsPage(),
      ),
    );
  }
}
