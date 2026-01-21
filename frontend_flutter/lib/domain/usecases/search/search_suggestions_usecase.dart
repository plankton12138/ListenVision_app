import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/search_repository.dart';
import '../base_usecase.dart';

/// 搜索建议用例
///
/// 负责获取搜索关键词建议
class SearchSuggestionsUseCase extends UseCase<List<String>, SuggestionsParams> {
  final SearchRepository _repository;

  SearchSuggestionsUseCase(this._repository);

  @override
  Future<Either<Failure, List<String>>> call(SuggestionsParams params) async {
    // 参数验证
    if (params.keyword.trim().isEmpty) {
      return const Left(DataFailure.invalidData(
        message: '搜索关键词不能为空',
      ));
    }

    // 最小关键词长度验证
    if (params.keyword.trim().length < 1) {
      return const Left(DataFailure.invalidData(
        message: '请输入至少1个字符',
      ));
    }

    // 调用仓储获取建议
    final result = await _repository.getSuggestions(
      keyword: params.keyword,
      limit: params.limit,
    );

    return result;
  }
}

/// 搜索建议参数
class SuggestionsParams {
  final String keyword;
  final int limit;

  const SuggestionsParams({
    required this.keyword,
    this.limit = 10,
  });
}
