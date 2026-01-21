import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/search_repository.dart';
import '../base_usecase.dart';

/// 热门关键词用例
///
/// 负责获取热门搜索关键词
class TrendingKeywordsUseCase extends NoParamsUseCase<List<String>> {
  final SearchRepository _repository;

  TrendingKeywordsUseCase(this._repository);

  @override
  Future<Either<Failure, List<String>>> execute() async {
    // 调用仓储获取热门关键词
    final result = await _repository.getTrendingKeywords(
      limit: 10,
    );

    return result;
  }
}
