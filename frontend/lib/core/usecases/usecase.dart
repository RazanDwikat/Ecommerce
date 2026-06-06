import 'package:dartz/dartz.dart';

import '../error/failures.dart';

/// Base contract for every use case.
///
/// [T] is the success result, [Params] are the inputs.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this for use cases that take no parameters.
class NoParams {
  const NoParams();
}
