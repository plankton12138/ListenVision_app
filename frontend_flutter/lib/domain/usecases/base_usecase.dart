import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

/// UseCase 基础类
///
/// Clean Architecture 中的 UseCase：
/// - 封装单一业务规则
/// - 输入类型 [Type]
/// - 输出 Either<Failure, ResultType>
/// - 可选参数 [Type]
abstract class UseCase<Type, Params> {
  /// 执行用例
  ///
  /// [params] 用例参数
  /// 返回 Either<Failure, Type>
  Future<Either<Failure, Type>> call(Params params);
}

/// 无参数用例
///
/// 用于不需要参数的用例
abstract class NoParamsUseCase<Type> extends UseCase<Type, NoParams> {
  @override
  Future<Either<Failure, Type>> call(NoParams params) => execute();

  /// 执行无参用例
  Future<Either<Failure, Type>> execute();
}

/// 同步用例
///
/// 用于同步操作的用例
abstract class SyncUseCase<Type, Params> {
  /// 执行同步用例
  Either<Failure, Type> call(Params params);
}

/// 无参数同步用例
abstract class NoParamsSyncUseCase<Type> extends SyncUseCase<Type, NoParams> {
  @override
  Either<Failure, Type> call(NoParams params) => execute();

  /// 执行无参同步用例
  Either<Failure, Type> execute();
}

/// 流式用例
///
/// 用于返回 Stream 的用例
abstract class StreamUseCase<Type, Params> {
  /// 执行流式用例
  Stream<Either<Failure, Type>> call(Params params);
}

/// 无参数标记类
class NoParams {
  const NoParams();
}
