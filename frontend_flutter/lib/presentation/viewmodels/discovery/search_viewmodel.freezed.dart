// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$SearchState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SearchStateCopyWith<$Res> {
  factory $SearchStateCopyWith(
    SearchState value,
    $Res Function(SearchState) then,
  ) = _$SearchStateCopyWithImpl<$Res, SearchState>;
}

/// @nodoc
class _$SearchStateCopyWithImpl<$Res, $Val extends SearchState>
    implements $SearchStateCopyWith<$Res> {
  _$SearchStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$SearchStateInitialImplCopyWith<$Res> {
  factory _$$SearchStateInitialImplCopyWith(
    _$SearchStateInitialImpl value,
    $Res Function(_$SearchStateInitialImpl) then,
  ) = __$$SearchStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchStateInitialImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateInitialImpl>
    implements _$$SearchStateInitialImplCopyWith<$Res> {
  __$$SearchStateInitialImplCopyWithImpl(
    _$SearchStateInitialImpl _value,
    $Res Function(_$SearchStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SearchStateInitialImpl implements SearchStateInitial {
  const _$SearchStateInitialImpl();

  @override
  String toString() {
    return 'SearchState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SearchStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class SearchStateInitial implements SearchState {
  const factory SearchStateInitial() = _$SearchStateInitialImpl;
}

/// @nodoc
abstract class _$$SearchStateLoadingImplCopyWith<$Res> {
  factory _$$SearchStateLoadingImplCopyWith(
    _$SearchStateLoadingImpl value,
    $Res Function(_$SearchStateLoadingImpl) then,
  ) = __$$SearchStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SearchStateLoadingImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateLoadingImpl>
    implements _$$SearchStateLoadingImplCopyWith<$Res> {
  __$$SearchStateLoadingImplCopyWithImpl(
    _$SearchStateLoadingImpl _value,
    $Res Function(_$SearchStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$SearchStateLoadingImpl implements SearchStateLoading {
  const _$SearchStateLoadingImpl();

  @override
  String toString() {
    return 'SearchState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SearchStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class SearchStateLoading implements SearchState {
  const factory SearchStateLoading() = _$SearchStateLoadingImpl;
}

/// @nodoc
abstract class _$$SearchStateResultsLoadedImplCopyWith<$Res> {
  factory _$$SearchStateResultsLoadedImplCopyWith(
    _$SearchStateResultsLoadedImpl value,
    $Res Function(_$SearchStateResultsLoadedImpl) then,
  ) = __$$SearchStateResultsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<SearchResultItem> results,
    String query,
    SearchPlatform platform,
  });
}

/// @nodoc
class __$$SearchStateResultsLoadedImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateResultsLoadedImpl>
    implements _$$SearchStateResultsLoadedImplCopyWith<$Res> {
  __$$SearchStateResultsLoadedImplCopyWithImpl(
    _$SearchStateResultsLoadedImpl _value,
    $Res Function(_$SearchStateResultsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? query = null,
    Object? platform = null,
  }) {
    return _then(
      _$SearchStateResultsLoadedImpl(
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<SearchResultItem>,
        query: null == query
            ? _value.query
            : query // ignore: cast_nullable_to_non_nullable
                  as String,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as SearchPlatform,
      ),
    );
  }
}

/// @nodoc

class _$SearchStateResultsLoadedImpl implements SearchStateResultsLoaded {
  const _$SearchStateResultsLoadedImpl({
    required final List<SearchResultItem> results,
    required this.query,
    required this.platform,
  }) : _results = results;

  final List<SearchResultItem> _results;
  @override
  List<SearchResultItem> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String query;
  @override
  final SearchPlatform platform;

  @override
  String toString() {
    return 'SearchState.resultsLoaded(results: $results, query: $query, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchStateResultsLoadedImpl &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.platform, platform) ||
                other.platform == platform));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_results),
    query,
    platform,
  );

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchStateResultsLoadedImplCopyWith<_$SearchStateResultsLoadedImpl>
  get copyWith =>
      __$$SearchStateResultsLoadedImplCopyWithImpl<
        _$SearchStateResultsLoadedImpl
      >(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) {
    return resultsLoaded(results, query, platform);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) {
    return resultsLoaded?.call(results, query, platform);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (resultsLoaded != null) {
      return resultsLoaded(results, query, platform);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) {
    return resultsLoaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) {
    return resultsLoaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) {
    if (resultsLoaded != null) {
      return resultsLoaded(this);
    }
    return orElse();
  }
}

abstract class SearchStateResultsLoaded implements SearchState {
  const factory SearchStateResultsLoaded({
    required final List<SearchResultItem> results,
    required final String query,
    required final SearchPlatform platform,
  }) = _$SearchStateResultsLoadedImpl;

  List<SearchResultItem> get results;
  String get query;
  SearchPlatform get platform;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchStateResultsLoadedImplCopyWith<_$SearchStateResultsLoadedImpl>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchStateIdleImplCopyWith<$Res> {
  factory _$$SearchStateIdleImplCopyWith(
    _$SearchStateIdleImpl value,
    $Res Function(_$SearchStateIdleImpl) then,
  ) = __$$SearchStateIdleImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<String> searchHistory,
    List<String> suggestions,
    SearchPlatform platform,
  });
}

/// @nodoc
class __$$SearchStateIdleImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateIdleImpl>
    implements _$$SearchStateIdleImplCopyWith<$Res> {
  __$$SearchStateIdleImplCopyWithImpl(
    _$SearchStateIdleImpl _value,
    $Res Function(_$SearchStateIdleImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchHistory = null,
    Object? suggestions = null,
    Object? platform = null,
  }) {
    return _then(
      _$SearchStateIdleImpl(
        searchHistory: null == searchHistory
            ? _value._searchHistory
            : searchHistory // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        suggestions: null == suggestions
            ? _value._suggestions
            : suggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        platform: null == platform
            ? _value.platform
            : platform // ignore: cast_nullable_to_non_nullable
                  as SearchPlatform,
      ),
    );
  }
}

/// @nodoc

class _$SearchStateIdleImpl implements SearchStateIdle {
  const _$SearchStateIdleImpl({
    final List<String> searchHistory = const [],
    final List<String> suggestions = const [],
    this.platform = SearchPlatform.bilibili,
  }) : _searchHistory = searchHistory,
       _suggestions = suggestions;

  final List<String> _searchHistory;
  @override
  @JsonKey()
  List<String> get searchHistory {
    if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_searchHistory);
  }

  final List<String> _suggestions;
  @override
  @JsonKey()
  List<String> get suggestions {
    if (_suggestions is EqualUnmodifiableListView) return _suggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestions);
  }

  @override
  @JsonKey()
  final SearchPlatform platform;

  @override
  String toString() {
    return 'SearchState.idle(searchHistory: $searchHistory, suggestions: $suggestions, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchStateIdleImpl &&
            const DeepCollectionEquality().equals(
              other._searchHistory,
              _searchHistory,
            ) &&
            const DeepCollectionEquality().equals(
              other._suggestions,
              _suggestions,
            ) &&
            (identical(other.platform, platform) ||
                other.platform == platform));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_searchHistory),
    const DeepCollectionEquality().hash(_suggestions),
    platform,
  );

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchStateIdleImplCopyWith<_$SearchStateIdleImpl> get copyWith =>
      __$$SearchStateIdleImplCopyWithImpl<_$SearchStateIdleImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) {
    return idle(searchHistory, suggestions, platform);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) {
    return idle?.call(searchHistory, suggestions, platform);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(searchHistory, suggestions, platform);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) {
    return idle(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) {
    return idle?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) {
    if (idle != null) {
      return idle(this);
    }
    return orElse();
  }
}

abstract class SearchStateIdle implements SearchState {
  const factory SearchStateIdle({
    final List<String> searchHistory,
    final List<String> suggestions,
    final SearchPlatform platform,
  }) = _$SearchStateIdleImpl;

  List<String> get searchHistory;
  List<String> get suggestions;
  SearchPlatform get platform;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchStateIdleImplCopyWith<_$SearchStateIdleImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SearchStateErrorImplCopyWith<$Res> {
  factory _$$SearchStateErrorImplCopyWith(
    _$SearchStateErrorImpl value,
    $Res Function(_$SearchStateErrorImpl) then,
  ) = __$$SearchStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$SearchStateErrorImplCopyWithImpl<$Res>
    extends _$SearchStateCopyWithImpl<$Res, _$SearchStateErrorImpl>
    implements _$$SearchStateErrorImplCopyWith<$Res> {
  __$$SearchStateErrorImplCopyWithImpl(
    _$SearchStateErrorImpl _value,
    $Res Function(_$SearchStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$SearchStateErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$SearchStateErrorImpl implements SearchStateError {
  const _$SearchStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'SearchState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SearchStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SearchStateErrorImplCopyWith<_$SearchStateErrorImpl> get copyWith =>
      __$$SearchStateErrorImplCopyWithImpl<_$SearchStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )
    resultsLoaded,
    required TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )
    idle,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult? Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<SearchResultItem> results,
      String query,
      SearchPlatform platform,
    )?
    resultsLoaded,
    TResult Function(
      List<String> searchHistory,
      List<String> suggestions,
      SearchPlatform platform,
    )?
    idle,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SearchStateInitial value) initial,
    required TResult Function(SearchStateLoading value) loading,
    required TResult Function(SearchStateResultsLoaded value) resultsLoaded,
    required TResult Function(SearchStateIdle value) idle,
    required TResult Function(SearchStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SearchStateInitial value)? initial,
    TResult? Function(SearchStateLoading value)? loading,
    TResult? Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult? Function(SearchStateIdle value)? idle,
    TResult? Function(SearchStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SearchStateInitial value)? initial,
    TResult Function(SearchStateLoading value)? loading,
    TResult Function(SearchStateResultsLoaded value)? resultsLoaded,
    TResult Function(SearchStateIdle value)? idle,
    TResult Function(SearchStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class SearchStateError implements SearchState {
  const factory SearchStateError({required final String message}) =
      _$SearchStateErrorImpl;

  String get message;

  /// Create a copy of SearchState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SearchStateErrorImplCopyWith<_$SearchStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
