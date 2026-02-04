// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playlist_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$PlaylistState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaylistStateCopyWith<$Res> {
  factory $PlaylistStateCopyWith(
    PlaylistState value,
    $Res Function(PlaylistState) then,
  ) = _$PlaylistStateCopyWithImpl<$Res, PlaylistState>;
}

/// @nodoc
class _$PlaylistStateCopyWithImpl<$Res, $Val extends PlaylistState>
    implements $PlaylistStateCopyWith<$Res> {
  _$PlaylistStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$PlaylistStateInitialImplCopyWith<$Res> {
  factory _$$PlaylistStateInitialImplCopyWith(
    _$PlaylistStateInitialImpl value,
    $Res Function(_$PlaylistStateInitialImpl) then,
  ) = __$$PlaylistStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PlaylistStateInitialImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateInitialImpl>
    implements _$$PlaylistStateInitialImplCopyWith<$Res> {
  __$$PlaylistStateInitialImplCopyWithImpl(
    _$PlaylistStateInitialImpl _value,
    $Res Function(_$PlaylistStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PlaylistStateInitialImpl implements PlaylistStateInitial {
  const _$PlaylistStateInitialImpl();

  @override
  String toString() {
    return 'PlaylistState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
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
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class PlaylistStateInitial implements PlaylistState {
  const factory PlaylistStateInitial() = _$PlaylistStateInitialImpl;
}

/// @nodoc
abstract class _$$PlaylistStateLoadingImplCopyWith<$Res> {
  factory _$$PlaylistStateLoadingImplCopyWith(
    _$PlaylistStateLoadingImpl value,
    $Res Function(_$PlaylistStateLoadingImpl) then,
  ) = __$$PlaylistStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$PlaylistStateLoadingImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateLoadingImpl>
    implements _$$PlaylistStateLoadingImplCopyWith<$Res> {
  __$$PlaylistStateLoadingImplCopyWithImpl(
    _$PlaylistStateLoadingImpl _value,
    $Res Function(_$PlaylistStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$PlaylistStateLoadingImpl implements PlaylistStateLoading {
  const _$PlaylistStateLoadingImpl();

  @override
  String toString() {
    return 'PlaylistState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
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
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class PlaylistStateLoading implements PlaylistState {
  const factory PlaylistStateLoading() = _$PlaylistStateLoadingImpl;
}

/// @nodoc
abstract class _$$PlaylistStateLoadedImplCopyWith<$Res> {
  factory _$$PlaylistStateLoadedImplCopyWith(
    _$PlaylistStateLoadedImpl value,
    $Res Function(_$PlaylistStateLoadedImpl) then,
  ) = __$$PlaylistStateLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<Playlist> playlists,
    List<Playlist> userPlaylists,
    List<Playlist> systemPlaylists,
    Playlist? favoritesPlaylist,
    Playlist? nowPlayingPlaylist,
    List<PlaylistItem> favoritesItems,
    List<PlaylistItem> nowPlayingItems,
  });

  $PlaylistCopyWith<$Res>? get favoritesPlaylist;
  $PlaylistCopyWith<$Res>? get nowPlayingPlaylist;
}

/// @nodoc
class __$$PlaylistStateLoadedImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateLoadedImpl>
    implements _$$PlaylistStateLoadedImplCopyWith<$Res> {
  __$$PlaylistStateLoadedImplCopyWithImpl(
    _$PlaylistStateLoadedImpl _value,
    $Res Function(_$PlaylistStateLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playlists = null,
    Object? userPlaylists = null,
    Object? systemPlaylists = null,
    Object? favoritesPlaylist = freezed,
    Object? nowPlayingPlaylist = freezed,
    Object? favoritesItems = null,
    Object? nowPlayingItems = null,
  }) {
    return _then(
      _$PlaylistStateLoadedImpl(
        playlists: null == playlists
            ? _value._playlists
            : playlists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        userPlaylists: null == userPlaylists
            ? _value._userPlaylists
            : userPlaylists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        systemPlaylists: null == systemPlaylists
            ? _value._systemPlaylists
            : systemPlaylists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        favoritesPlaylist: freezed == favoritesPlaylist
            ? _value.favoritesPlaylist
            : favoritesPlaylist // ignore: cast_nullable_to_non_nullable
                  as Playlist?,
        nowPlayingPlaylist: freezed == nowPlayingPlaylist
            ? _value.nowPlayingPlaylist
            : nowPlayingPlaylist // ignore: cast_nullable_to_non_nullable
                  as Playlist?,
        favoritesItems: null == favoritesItems
            ? _value._favoritesItems
            : favoritesItems // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItem>,
        nowPlayingItems: null == nowPlayingItems
            ? _value._nowPlayingItems
            : nowPlayingItems // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItem>,
      ),
    );
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res>? get favoritesPlaylist {
    if (_value.favoritesPlaylist == null) {
      return null;
    }

    return $PlaylistCopyWith<$Res>(_value.favoritesPlaylist!, (value) {
      return _then(_value.copyWith(favoritesPlaylist: value));
    });
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res>? get nowPlayingPlaylist {
    if (_value.nowPlayingPlaylist == null) {
      return null;
    }

    return $PlaylistCopyWith<$Res>(_value.nowPlayingPlaylist!, (value) {
      return _then(_value.copyWith(nowPlayingPlaylist: value));
    });
  }
}

/// @nodoc

class _$PlaylistStateLoadedImpl implements PlaylistStateLoaded {
  const _$PlaylistStateLoadedImpl({
    required final List<Playlist> playlists,
    required final List<Playlist> userPlaylists,
    required final List<Playlist> systemPlaylists,
    this.favoritesPlaylist,
    this.nowPlayingPlaylist,
    final List<PlaylistItem> favoritesItems = const [],
    final List<PlaylistItem> nowPlayingItems = const [],
  }) : _playlists = playlists,
       _userPlaylists = userPlaylists,
       _systemPlaylists = systemPlaylists,
       _favoritesItems = favoritesItems,
       _nowPlayingItems = nowPlayingItems;

  final List<Playlist> _playlists;
  @override
  List<Playlist> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  final List<Playlist> _userPlaylists;
  @override
  List<Playlist> get userPlaylists {
    if (_userPlaylists is EqualUnmodifiableListView) return _userPlaylists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userPlaylists);
  }

  final List<Playlist> _systemPlaylists;
  @override
  List<Playlist> get systemPlaylists {
    if (_systemPlaylists is EqualUnmodifiableListView) return _systemPlaylists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_systemPlaylists);
  }

  @override
  final Playlist? favoritesPlaylist;
  @override
  final Playlist? nowPlayingPlaylist;
  final List<PlaylistItem> _favoritesItems;
  @override
  @JsonKey()
  List<PlaylistItem> get favoritesItems {
    if (_favoritesItems is EqualUnmodifiableListView) return _favoritesItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoritesItems);
  }

  final List<PlaylistItem> _nowPlayingItems;
  @override
  @JsonKey()
  List<PlaylistItem> get nowPlayingItems {
    if (_nowPlayingItems is EqualUnmodifiableListView) return _nowPlayingItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nowPlayingItems);
  }

  @override
  String toString() {
    return 'PlaylistState.loaded(playlists: $playlists, userPlaylists: $userPlaylists, systemPlaylists: $systemPlaylists, favoritesPlaylist: $favoritesPlaylist, nowPlayingPlaylist: $nowPlayingPlaylist, favoritesItems: $favoritesItems, nowPlayingItems: $nowPlayingItems)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateLoadedImpl &&
            const DeepCollectionEquality().equals(
              other._playlists,
              _playlists,
            ) &&
            const DeepCollectionEquality().equals(
              other._userPlaylists,
              _userPlaylists,
            ) &&
            const DeepCollectionEquality().equals(
              other._systemPlaylists,
              _systemPlaylists,
            ) &&
            (identical(other.favoritesPlaylist, favoritesPlaylist) ||
                other.favoritesPlaylist == favoritesPlaylist) &&
            (identical(other.nowPlayingPlaylist, nowPlayingPlaylist) ||
                other.nowPlayingPlaylist == nowPlayingPlaylist) &&
            const DeepCollectionEquality().equals(
              other._favoritesItems,
              _favoritesItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._nowPlayingItems,
              _nowPlayingItems,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_playlists),
    const DeepCollectionEquality().hash(_userPlaylists),
    const DeepCollectionEquality().hash(_systemPlaylists),
    favoritesPlaylist,
    nowPlayingPlaylist,
    const DeepCollectionEquality().hash(_favoritesItems),
    const DeepCollectionEquality().hash(_nowPlayingItems),
  );

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistStateLoadedImplCopyWith<_$PlaylistStateLoadedImpl> get copyWith =>
      __$$PlaylistStateLoadedImplCopyWithImpl<_$PlaylistStateLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) {
    return loaded(
      playlists,
      userPlaylists,
      systemPlaylists,
      favoritesPlaylist,
      nowPlayingPlaylist,
      favoritesItems,
      nowPlayingItems,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) {
    return loaded?.call(
      playlists,
      userPlaylists,
      systemPlaylists,
      favoritesPlaylist,
      nowPlayingPlaylist,
      favoritesItems,
      nowPlayingItems,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(
        playlists,
        userPlaylists,
        systemPlaylists,
        favoritesPlaylist,
        nowPlayingPlaylist,
        favoritesItems,
        nowPlayingItems,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class PlaylistStateLoaded implements PlaylistState {
  const factory PlaylistStateLoaded({
    required final List<Playlist> playlists,
    required final List<Playlist> userPlaylists,
    required final List<Playlist> systemPlaylists,
    final Playlist? favoritesPlaylist,
    final Playlist? nowPlayingPlaylist,
    final List<PlaylistItem> favoritesItems,
    final List<PlaylistItem> nowPlayingItems,
  }) = _$PlaylistStateLoadedImpl;

  List<Playlist> get playlists;
  List<Playlist> get userPlaylists;
  List<Playlist> get systemPlaylists;
  Playlist? get favoritesPlaylist;
  Playlist? get nowPlayingPlaylist;
  List<PlaylistItem> get favoritesItems;
  List<PlaylistItem> get nowPlayingItems;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistStateLoadedImplCopyWith<_$PlaylistStateLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlaylistStateErrorImplCopyWith<$Res> {
  factory _$$PlaylistStateErrorImplCopyWith(
    _$PlaylistStateErrorImpl value,
    $Res Function(_$PlaylistStateErrorImpl) then,
  ) = __$$PlaylistStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$PlaylistStateErrorImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateErrorImpl>
    implements _$$PlaylistStateErrorImplCopyWith<$Res> {
  __$$PlaylistStateErrorImplCopyWithImpl(
    _$PlaylistStateErrorImpl _value,
    $Res Function(_$PlaylistStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$PlaylistStateErrorImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$PlaylistStateErrorImpl implements PlaylistStateError {
  const _$PlaylistStateErrorImpl({required this.message});

  @override
  final String message;

  @override
  String toString() {
    return 'PlaylistState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistStateErrorImplCopyWith<_$PlaylistStateErrorImpl> get copyWith =>
      __$$PlaylistStateErrorImplCopyWithImpl<_$PlaylistStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
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
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class PlaylistStateError implements PlaylistState {
  const factory PlaylistStateError({required final String message}) =
      _$PlaylistStateErrorImpl;

  String get message;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistStateErrorImplCopyWith<_$PlaylistStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$PlaylistStateOperatingImplCopyWith<$Res> {
  factory _$$PlaylistStateOperatingImplCopyWith(
    _$PlaylistStateOperatingImpl value,
    $Res Function(_$PlaylistStateOperatingImpl) then,
  ) = __$$PlaylistStateOperatingImplCopyWithImpl<$Res>;
  @useResult
  $Res call({
    List<Playlist> playlists,
    List<Playlist> userPlaylists,
    List<Playlist> systemPlaylists,
    Playlist? favoritesPlaylist,
    Playlist? nowPlayingPlaylist,
    List<PlaylistItem> favoritesItems,
    List<PlaylistItem> nowPlayingItems,
    String? operationMessage,
  });

  $PlaylistCopyWith<$Res>? get favoritesPlaylist;
  $PlaylistCopyWith<$Res>? get nowPlayingPlaylist;
}

/// @nodoc
class __$$PlaylistStateOperatingImplCopyWithImpl<$Res>
    extends _$PlaylistStateCopyWithImpl<$Res, _$PlaylistStateOperatingImpl>
    implements _$$PlaylistStateOperatingImplCopyWith<$Res> {
  __$$PlaylistStateOperatingImplCopyWithImpl(
    _$PlaylistStateOperatingImpl _value,
    $Res Function(_$PlaylistStateOperatingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? playlists = null,
    Object? userPlaylists = null,
    Object? systemPlaylists = null,
    Object? favoritesPlaylist = freezed,
    Object? nowPlayingPlaylist = freezed,
    Object? favoritesItems = null,
    Object? nowPlayingItems = null,
    Object? operationMessage = freezed,
  }) {
    return _then(
      _$PlaylistStateOperatingImpl(
        playlists: null == playlists
            ? _value._playlists
            : playlists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        userPlaylists: null == userPlaylists
            ? _value._userPlaylists
            : userPlaylists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        systemPlaylists: null == systemPlaylists
            ? _value._systemPlaylists
            : systemPlaylists // ignore: cast_nullable_to_non_nullable
                  as List<Playlist>,
        favoritesPlaylist: freezed == favoritesPlaylist
            ? _value.favoritesPlaylist
            : favoritesPlaylist // ignore: cast_nullable_to_non_nullable
                  as Playlist?,
        nowPlayingPlaylist: freezed == nowPlayingPlaylist
            ? _value.nowPlayingPlaylist
            : nowPlayingPlaylist // ignore: cast_nullable_to_non_nullable
                  as Playlist?,
        favoritesItems: null == favoritesItems
            ? _value._favoritesItems
            : favoritesItems // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItem>,
        nowPlayingItems: null == nowPlayingItems
            ? _value._nowPlayingItems
            : nowPlayingItems // ignore: cast_nullable_to_non_nullable
                  as List<PlaylistItem>,
        operationMessage: freezed == operationMessage
            ? _value.operationMessage
            : operationMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res>? get favoritesPlaylist {
    if (_value.favoritesPlaylist == null) {
      return null;
    }

    return $PlaylistCopyWith<$Res>(_value.favoritesPlaylist!, (value) {
      return _then(_value.copyWith(favoritesPlaylist: value));
    });
  }

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PlaylistCopyWith<$Res>? get nowPlayingPlaylist {
    if (_value.nowPlayingPlaylist == null) {
      return null;
    }

    return $PlaylistCopyWith<$Res>(_value.nowPlayingPlaylist!, (value) {
      return _then(_value.copyWith(nowPlayingPlaylist: value));
    });
  }
}

/// @nodoc

class _$PlaylistStateOperatingImpl implements PlaylistStateOperating {
  const _$PlaylistStateOperatingImpl({
    required final List<Playlist> playlists,
    required final List<Playlist> userPlaylists,
    required final List<Playlist> systemPlaylists,
    this.favoritesPlaylist,
    this.nowPlayingPlaylist,
    final List<PlaylistItem> favoritesItems = const [],
    final List<PlaylistItem> nowPlayingItems = const [],
    this.operationMessage,
  }) : _playlists = playlists,
       _userPlaylists = userPlaylists,
       _systemPlaylists = systemPlaylists,
       _favoritesItems = favoritesItems,
       _nowPlayingItems = nowPlayingItems;

  final List<Playlist> _playlists;
  @override
  List<Playlist> get playlists {
    if (_playlists is EqualUnmodifiableListView) return _playlists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_playlists);
  }

  final List<Playlist> _userPlaylists;
  @override
  List<Playlist> get userPlaylists {
    if (_userPlaylists is EqualUnmodifiableListView) return _userPlaylists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_userPlaylists);
  }

  final List<Playlist> _systemPlaylists;
  @override
  List<Playlist> get systemPlaylists {
    if (_systemPlaylists is EqualUnmodifiableListView) return _systemPlaylists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_systemPlaylists);
  }

  @override
  final Playlist? favoritesPlaylist;
  @override
  final Playlist? nowPlayingPlaylist;
  final List<PlaylistItem> _favoritesItems;
  @override
  @JsonKey()
  List<PlaylistItem> get favoritesItems {
    if (_favoritesItems is EqualUnmodifiableListView) return _favoritesItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_favoritesItems);
  }

  final List<PlaylistItem> _nowPlayingItems;
  @override
  @JsonKey()
  List<PlaylistItem> get nowPlayingItems {
    if (_nowPlayingItems is EqualUnmodifiableListView) return _nowPlayingItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_nowPlayingItems);
  }

  @override
  final String? operationMessage;

  @override
  String toString() {
    return 'PlaylistState.operating(playlists: $playlists, userPlaylists: $userPlaylists, systemPlaylists: $systemPlaylists, favoritesPlaylist: $favoritesPlaylist, nowPlayingPlaylist: $nowPlayingPlaylist, favoritesItems: $favoritesItems, nowPlayingItems: $nowPlayingItems, operationMessage: $operationMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaylistStateOperatingImpl &&
            const DeepCollectionEquality().equals(
              other._playlists,
              _playlists,
            ) &&
            const DeepCollectionEquality().equals(
              other._userPlaylists,
              _userPlaylists,
            ) &&
            const DeepCollectionEquality().equals(
              other._systemPlaylists,
              _systemPlaylists,
            ) &&
            (identical(other.favoritesPlaylist, favoritesPlaylist) ||
                other.favoritesPlaylist == favoritesPlaylist) &&
            (identical(other.nowPlayingPlaylist, nowPlayingPlaylist) ||
                other.nowPlayingPlaylist == nowPlayingPlaylist) &&
            const DeepCollectionEquality().equals(
              other._favoritesItems,
              _favoritesItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._nowPlayingItems,
              _nowPlayingItems,
            ) &&
            (identical(other.operationMessage, operationMessage) ||
                other.operationMessage == operationMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_playlists),
    const DeepCollectionEquality().hash(_userPlaylists),
    const DeepCollectionEquality().hash(_systemPlaylists),
    favoritesPlaylist,
    nowPlayingPlaylist,
    const DeepCollectionEquality().hash(_favoritesItems),
    const DeepCollectionEquality().hash(_nowPlayingItems),
    operationMessage,
  );

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaylistStateOperatingImplCopyWith<_$PlaylistStateOperatingImpl>
  get copyWith =>
      __$$PlaylistStateOperatingImplCopyWithImpl<_$PlaylistStateOperatingImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )
    loaded,
    required TResult Function(String message) error,
    required TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )
    operating,
  }) {
    return operating(
      playlists,
      userPlaylists,
      systemPlaylists,
      favoritesPlaylist,
      nowPlayingPlaylist,
      favoritesItems,
      nowPlayingItems,
      operationMessage,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult? Function(String message)? error,
    TResult? Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
  }) {
    return operating?.call(
      playlists,
      userPlaylists,
      systemPlaylists,
      favoritesPlaylist,
      nowPlayingPlaylist,
      favoritesItems,
      nowPlayingItems,
      operationMessage,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
    )?
    loaded,
    TResult Function(String message)? error,
    TResult Function(
      List<Playlist> playlists,
      List<Playlist> userPlaylists,
      List<Playlist> systemPlaylists,
      Playlist? favoritesPlaylist,
      Playlist? nowPlayingPlaylist,
      List<PlaylistItem> favoritesItems,
      List<PlaylistItem> nowPlayingItems,
      String? operationMessage,
    )?
    operating,
    required TResult orElse(),
  }) {
    if (operating != null) {
      return operating(
        playlists,
        userPlaylists,
        systemPlaylists,
        favoritesPlaylist,
        nowPlayingPlaylist,
        favoritesItems,
        nowPlayingItems,
        operationMessage,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(PlaylistStateInitial value) initial,
    required TResult Function(PlaylistStateLoading value) loading,
    required TResult Function(PlaylistStateLoaded value) loaded,
    required TResult Function(PlaylistStateError value) error,
    required TResult Function(PlaylistStateOperating value) operating,
  }) {
    return operating(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(PlaylistStateInitial value)? initial,
    TResult? Function(PlaylistStateLoading value)? loading,
    TResult? Function(PlaylistStateLoaded value)? loaded,
    TResult? Function(PlaylistStateError value)? error,
    TResult? Function(PlaylistStateOperating value)? operating,
  }) {
    return operating?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(PlaylistStateInitial value)? initial,
    TResult Function(PlaylistStateLoading value)? loading,
    TResult Function(PlaylistStateLoaded value)? loaded,
    TResult Function(PlaylistStateError value)? error,
    TResult Function(PlaylistStateOperating value)? operating,
    required TResult orElse(),
  }) {
    if (operating != null) {
      return operating(this);
    }
    return orElse();
  }
}

abstract class PlaylistStateOperating implements PlaylistState {
  const factory PlaylistStateOperating({
    required final List<Playlist> playlists,
    required final List<Playlist> userPlaylists,
    required final List<Playlist> systemPlaylists,
    final Playlist? favoritesPlaylist,
    final Playlist? nowPlayingPlaylist,
    final List<PlaylistItem> favoritesItems,
    final List<PlaylistItem> nowPlayingItems,
    final String? operationMessage,
  }) = _$PlaylistStateOperatingImpl;

  List<Playlist> get playlists;
  List<Playlist> get userPlaylists;
  List<Playlist> get systemPlaylists;
  Playlist? get favoritesPlaylist;
  Playlist? get nowPlayingPlaylist;
  List<PlaylistItem> get favoritesItems;
  List<PlaylistItem> get nowPlayingItems;
  String? get operationMessage;

  /// Create a copy of PlaylistState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaylistStateOperatingImplCopyWith<_$PlaylistStateOperatingImpl>
  get copyWith => throw _privateConstructorUsedError;
}
