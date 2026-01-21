import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/search_repository.dart';
import '../base_usecase.dart';
import '../../entities/audio.dart';

/// 本地搜索用例
///
/// 负责本地音频搜索业务逻辑
class LocalSearchUseCase extends UseCase<List<Audio>, SearchParams> {
  final SearchRepository _repository;

  LocalSearchUseCase(this._repository);

  @override
  Future<Either<Failure, List<Audio>>> call(SearchParams params) async {
    // 参数验证
    if (params.keyword.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '搜索关键词不能为空',
      ));
    }

    // 最小关键词长度验证
    if (params.keyword.trim().length < 2) {
      return const Left(DataFailure.invalidData(
        message: '搜索关键词至少需要2个字符',
      ));
    }

    // 调用仓储搜索
    final result = await _repository.search(
      keyword: params.keyword,
      limit: params.limit,
    );

    return result;
  }
}

/// 搜索参数
class SearchParams {
  final String keyword;
  final int limit;

  const SearchParams({
    required this.keyword,
    this.limit = 20,
  });
}
