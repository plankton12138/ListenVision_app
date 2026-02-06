// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchState()';
}


}

/// @nodoc
class $SearchStateCopyWith<$Res>  {
$SearchStateCopyWith(SearchState _, $Res Function(SearchState) __);
}


/// Adds pattern-matching-related methods to [SearchState].
extension SearchStatePatterns on SearchState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SearchStateInitial value)?  initial,TResult Function( SearchStateLoading value)?  loading,TResult Function( SearchStateResultsLoaded value)?  resultsLoaded,TResult Function( SearchStateIdle value)?  idle,TResult Function( SearchStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SearchStateInitial() when initial != null:
return initial(_that);case SearchStateLoading() when loading != null:
return loading(_that);case SearchStateResultsLoaded() when resultsLoaded != null:
return resultsLoaded(_that);case SearchStateIdle() when idle != null:
return idle(_that);case SearchStateError() when error != null:
return error(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SearchStateInitial value)  initial,required TResult Function( SearchStateLoading value)  loading,required TResult Function( SearchStateResultsLoaded value)  resultsLoaded,required TResult Function( SearchStateIdle value)  idle,required TResult Function( SearchStateError value)  error,}){
final _that = this;
switch (_that) {
case SearchStateInitial():
return initial(_that);case SearchStateLoading():
return loading(_that);case SearchStateResultsLoaded():
return resultsLoaded(_that);case SearchStateIdle():
return idle(_that);case SearchStateError():
return error(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SearchStateInitial value)?  initial,TResult? Function( SearchStateLoading value)?  loading,TResult? Function( SearchStateResultsLoaded value)?  resultsLoaded,TResult? Function( SearchStateIdle value)?  idle,TResult? Function( SearchStateError value)?  error,}){
final _that = this;
switch (_that) {
case SearchStateInitial() when initial != null:
return initial(_that);case SearchStateLoading() when loading != null:
return loading(_that);case SearchStateResultsLoaded() when resultsLoaded != null:
return resultsLoaded(_that);case SearchStateIdle() when idle != null:
return idle(_that);case SearchStateError() when error != null:
return error(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<SearchResultItem> results,  String query,  SearchPlatform platform,  int currentPage,  int pageSize,  int totalCount,  bool hasMore)?  resultsLoaded,TResult Function( List<String> searchHistory,  List<String> suggestions,  SearchPlatform platform)?  idle,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SearchStateInitial() when initial != null:
return initial();case SearchStateLoading() when loading != null:
return loading();case SearchStateResultsLoaded() when resultsLoaded != null:
return resultsLoaded(_that.results,_that.query,_that.platform,_that.currentPage,_that.pageSize,_that.totalCount,_that.hasMore);case SearchStateIdle() when idle != null:
return idle(_that.searchHistory,_that.suggestions,_that.platform);case SearchStateError() when error != null:
return error(_that.message);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<SearchResultItem> results,  String query,  SearchPlatform platform,  int currentPage,  int pageSize,  int totalCount,  bool hasMore)  resultsLoaded,required TResult Function( List<String> searchHistory,  List<String> suggestions,  SearchPlatform platform)  idle,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case SearchStateInitial():
return initial();case SearchStateLoading():
return loading();case SearchStateResultsLoaded():
return resultsLoaded(_that.results,_that.query,_that.platform,_that.currentPage,_that.pageSize,_that.totalCount,_that.hasMore);case SearchStateIdle():
return idle(_that.searchHistory,_that.suggestions,_that.platform);case SearchStateError():
return error(_that.message);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<SearchResultItem> results,  String query,  SearchPlatform platform,  int currentPage,  int pageSize,  int totalCount,  bool hasMore)?  resultsLoaded,TResult? Function( List<String> searchHistory,  List<String> suggestions,  SearchPlatform platform)?  idle,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case SearchStateInitial() when initial != null:
return initial();case SearchStateLoading() when loading != null:
return loading();case SearchStateResultsLoaded() when resultsLoaded != null:
return resultsLoaded(_that.results,_that.query,_that.platform,_that.currentPage,_that.pageSize,_that.totalCount,_that.hasMore);case SearchStateIdle() when idle != null:
return idle(_that.searchHistory,_that.suggestions,_that.platform);case SearchStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class SearchStateInitial implements SearchState {
  const SearchStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchState.initial()';
}


}




/// @nodoc


class SearchStateLoading implements SearchState {
  const SearchStateLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStateLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SearchState.loading()';
}


}




/// @nodoc


class SearchStateResultsLoaded implements SearchState {
  const SearchStateResultsLoaded({required final  List<SearchResultItem> results, required this.query, required this.platform, this.currentPage = 1, this.pageSize = 20, this.totalCount = 0, this.hasMore = false}): _results = results;
  

 final  List<SearchResultItem> _results;
 List<SearchResultItem> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

 final  String query;
 final  SearchPlatform platform;
@JsonKey() final  int currentPage;
@JsonKey() final  int pageSize;
@JsonKey() final  int totalCount;
@JsonKey() final  bool hasMore;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateResultsLoadedCopyWith<SearchStateResultsLoaded> get copyWith => _$SearchStateResultsLoadedCopyWithImpl<SearchStateResultsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStateResultsLoaded&&const DeepCollectionEquality().equals(other._results, _results)&&(identical(other.query, query) || other.query == query)&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.currentPage, currentPage) || other.currentPage == currentPage)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.totalCount, totalCount) || other.totalCount == totalCount)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_results),query,platform,currentPage,pageSize,totalCount,hasMore);

@override
String toString() {
  return 'SearchState.resultsLoaded(results: $results, query: $query, platform: $platform, currentPage: $currentPage, pageSize: $pageSize, totalCount: $totalCount, hasMore: $hasMore)';
}


}

/// @nodoc
abstract mixin class $SearchStateResultsLoadedCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory $SearchStateResultsLoadedCopyWith(SearchStateResultsLoaded value, $Res Function(SearchStateResultsLoaded) _then) = _$SearchStateResultsLoadedCopyWithImpl;
@useResult
$Res call({
 List<SearchResultItem> results, String query, SearchPlatform platform, int currentPage, int pageSize, int totalCount, bool hasMore
});




}
/// @nodoc
class _$SearchStateResultsLoadedCopyWithImpl<$Res>
    implements $SearchStateResultsLoadedCopyWith<$Res> {
  _$SearchStateResultsLoadedCopyWithImpl(this._self, this._then);

  final SearchStateResultsLoaded _self;
  final $Res Function(SearchStateResultsLoaded) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? results = null,Object? query = null,Object? platform = null,Object? currentPage = null,Object? pageSize = null,Object? totalCount = null,Object? hasMore = null,}) {
  return _then(SearchStateResultsLoaded(
results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SearchResultItem>,query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SearchPlatform,currentPage: null == currentPage ? _self.currentPage : currentPage // ignore: cast_nullable_to_non_nullable
as int,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,totalCount: null == totalCount ? _self.totalCount : totalCount // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class SearchStateIdle implements SearchState {
  const SearchStateIdle({final  List<String> searchHistory = const [], final  List<String> suggestions = const [], this.platform = SearchPlatform.bilibili}): _searchHistory = searchHistory,_suggestions = suggestions;
  

 final  List<String> _searchHistory;
@JsonKey() List<String> get searchHistory {
  if (_searchHistory is EqualUnmodifiableListView) return _searchHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_searchHistory);
}

 final  List<String> _suggestions;
@JsonKey() List<String> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

@JsonKey() final  SearchPlatform platform;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateIdleCopyWith<SearchStateIdle> get copyWith => _$SearchStateIdleCopyWithImpl<SearchStateIdle>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStateIdle&&const DeepCollectionEquality().equals(other._searchHistory, _searchHistory)&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.platform, platform) || other.platform == platform));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_searchHistory),const DeepCollectionEquality().hash(_suggestions),platform);

@override
String toString() {
  return 'SearchState.idle(searchHistory: $searchHistory, suggestions: $suggestions, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $SearchStateIdleCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory $SearchStateIdleCopyWith(SearchStateIdle value, $Res Function(SearchStateIdle) _then) = _$SearchStateIdleCopyWithImpl;
@useResult
$Res call({
 List<String> searchHistory, List<String> suggestions, SearchPlatform platform
});




}
/// @nodoc
class _$SearchStateIdleCopyWithImpl<$Res>
    implements $SearchStateIdleCopyWith<$Res> {
  _$SearchStateIdleCopyWithImpl(this._self, this._then);

  final SearchStateIdle _self;
  final $Res Function(SearchStateIdle) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? searchHistory = null,Object? suggestions = null,Object? platform = null,}) {
  return _then(SearchStateIdle(
searchHistory: null == searchHistory ? _self._searchHistory : searchHistory // ignore: cast_nullable_to_non_nullable
as List<String>,suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as SearchPlatform,
  ));
}


}

/// @nodoc


class SearchStateError implements SearchState {
  const SearchStateError({required this.message});
  

 final  String message;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchStateErrorCopyWith<SearchStateError> get copyWith => _$SearchStateErrorCopyWithImpl<SearchStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SearchState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $SearchStateErrorCopyWith<$Res> implements $SearchStateCopyWith<$Res> {
  factory $SearchStateErrorCopyWith(SearchStateError value, $Res Function(SearchStateError) _then) = _$SearchStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SearchStateErrorCopyWithImpl<$Res>
    implements $SearchStateErrorCopyWith<$Res> {
  _$SearchStateErrorCopyWithImpl(this._self, this._then);

  final SearchStateError _self;
  final $Res Function(SearchStateError) _then;

/// Create a copy of SearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SearchStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
