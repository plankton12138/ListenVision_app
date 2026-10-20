import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:listenvision/models/audio.dart';
import 'package:listenvision/presentation/viewmodels/discovery/search_viewmodel.dart';
import 'package:listenvision/services/bilibili_api_service.dart';

class ControlledSearchApi extends BilibiliApiService {
  final searches = <String, Completer<List<Audio>>>{};
  final suggestions = <String, Completer<List<String>>>{};
  final tokens = <CancelToken>[];
  @override
  Future<List<Audio>> search({
    required String keyword,
    int page = 1,
    int pageSize = 20,
    CancelToken? cancelToken,
  }) {
    tokens.add(cancelToken!);
    return (searches['$keyword:$page'] = Completer<List<Audio>>()).future;
  }

  @override
  Future<List<String>> getSearchSuggestions(
    String keyword, {
    CancelToken? cancelToken,
  }) {
    return (suggestions[keyword] = Completer<List<String>>()).future;
  }
}

void main() {
  late ControlledSearchApi api;
  late ProviderContainer container;
  late SearchViewModel vm;
  setUp(() async {
    api = ControlledSearchApi();
    container = ProviderContainer(
      overrides: [bilibiliApiServiceProvider.overrideWithValue(api)],
    );
    await container.read(searchViewModelProvider.future);
    vm = container.read(searchViewModelProvider.notifier);
  });
  tearDown(() => container.dispose());

  SearchStateResultsLoaded results() =>
      container.read(searchViewModelProvider).requireValue
          as SearchStateResultsLoaded;

  test('旧搜索最后完成也不能覆盖新结果，旧请求收到取消信号', () async {
    final a = vm.search('A');
    final b = vm.search('B');
    expect(api.tokens.first.isCancelled, isTrue);
    api.searches['B:1']!.complete([const Audio(id: 'B', title: 'B')]);
    expect(await b, isTrue);
    api.searches['A:1']!.complete([const Audio(id: 'A', title: 'A')]);
    expect(await a, isFalse);
    expect(results().query, 'B');
    expect(results().results.single.bvid, 'B');
  });

  test('清空时使在途搜索失效，旧错误不能覆盖 idle', () async {
    final pending = vm.search('A');
    vm.clearSearchResults();
    api.searches['A:1']!.completeError(Exception('old error'));
    expect(await pending, isFalse);
    expect(
      container.read(searchViewModelProvider).requireValue,
      isA<SearchStateIdle>(),
    );
  });

  test('当前搜索失败退出 loading，随后可以重试', () async {
    final pending = vm.search('A');
    api.searches['A:1']!.completeError(Exception('timeout'));
    expect(await pending, isFalse);
    expect(container.read(searchViewModelProvider).hasError, isTrue);
    final retry = vm.search('A');
    api.searches['A:1']!.complete([]);
    expect(await retry, isTrue);
  });

  test('分页去重且阻止同一页并发请求', () async {
    final first = vm.search('A');
    api.searches['A:1']!.complete(
      List.generate(20, (i) => Audio(id: '$i', title: '$i')),
    );
    await first;
    final page = vm.loadNextPage();
    expect(await vm.loadNextPage(), isFalse);
    api.searches['A:2']!.complete([
      const Audio(id: '0', title: 'duplicate'),
      const Audio(id: '20', title: 'new'),
    ]);
    expect(await page, isTrue);
    expect(results().results.length, 21);
    expect(results().currentPage, 2);
  });

  test('旧分页在新搜索后返回不能污染新列表', () async {
    final first = vm.search('A');
    api.searches['A:1']!.complete(
      List.generate(20, (i) => Audio(id: '$i', title: '$i')),
    );
    await first;
    final page = vm.loadNextPage();
    final b = vm.search('B');
    api.searches['B:1']!.complete([const Audio(id: 'B', title: 'B')]);
    await b;
    api.searches['A:2']!.complete([const Audio(id: 'old', title: 'old')]);
    expect(await page, isFalse);
    expect(results().query, 'B');
    expect(results().results.single.bvid, 'B');
  });

  test('搜索建议防抖，短输入取消待发请求', () async {
    final a = vm.getSearchSuggestions('ab');
    final b = vm.getSearchSuggestions('abc');
    expect(await a, isFalse);
    expect(api.suggestions, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(api.suggestions.keys, ['abc']);
    await vm.getSearchSuggestions('a');
    api.suggestions['abc']!.complete(['old']);
    expect(await b, isFalse);
    expect(
      (container.read(searchViewModelProvider).requireValue as SearchStateIdle)
          .suggestions,
      isEmpty,
    );
  });

  test('搜索建议不能将新搜索结果覆盖为 idle', () async {
    final suggestion = vm.getSearchSuggestions('ab');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final search = vm.search('music');
    api.searches['music:1']!.complete([
      const Audio(id: 'music', title: 'music'),
    ]);
    await search;
    api.suggestions['ab']!.complete(['old']);
    expect(await suggestion, isFalse);
    expect(results().query, 'music');
  });
}
