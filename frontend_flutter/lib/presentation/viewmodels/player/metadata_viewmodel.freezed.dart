// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metadata_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MetadataState {
  /// 是否正在加载
  bool get isLoading => throw _privateConstructorUsedError;

  /// 已加载的本地音频元数据（文件路径 -> 元数据）
  Map<String, AudioMetadata> get localMetadata =>
      throw _privateConstructorUsedError;

  /// 封面缓存（URL -> Uint8List）
  Map<String, Uint8List> get coverCache => throw _privateConstructorUsedError;

  /// 错误消息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of MetadataState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MetadataStateCopyWith<MetadataState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MetadataStateCopyWith<$Res> {
  factory $MetadataStateCopyWith(
    MetadataState value,
    $Res Function(MetadataState) then,
  ) = _$MetadataStateCopyWithImpl<$Res, MetadataState>;
  @useResult
  $Res call({
    bool isLoading,
    Map<String, AudioMetadata> localMetadata,
    Map<String, Uint8List> coverCache,
    String? errorMessage,
  });
}

/// @nodoc
class _$MetadataStateCopyWithImpl<$Res, $Val extends MetadataState>
    implements $MetadataStateCopyWith<$Res> {
  _$MetadataStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MetadataState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? localMetadata = null,
    Object? coverCache = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            localMetadata: null == localMetadata
                ? _value.localMetadata
                : localMetadata // ignore: cast_nullable_to_non_nullable
                      as Map<String, AudioMetadata>,
            coverCache: null == coverCache
                ? _value.coverCache
                : coverCache // ignore: cast_nullable_to_non_nullable
                      as Map<String, Uint8List>,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MetadataStateImplCopyWith<$Res>
    implements $MetadataStateCopyWith<$Res> {
  factory _$$MetadataStateImplCopyWith(
    _$MetadataStateImpl value,
    $Res Function(_$MetadataStateImpl) then,
  ) = __$$MetadataStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isLoading,
    Map<String, AudioMetadata> localMetadata,
    Map<String, Uint8List> coverCache,
    String? errorMessage,
  });
}

/// @nodoc
class __$$MetadataStateImplCopyWithImpl<$Res>
    extends _$MetadataStateCopyWithImpl<$Res, _$MetadataStateImpl>
    implements _$$MetadataStateImplCopyWith<$Res> {
  __$$MetadataStateImplCopyWithImpl(
    _$MetadataStateImpl _value,
    $Res Function(_$MetadataStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MetadataState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? localMetadata = null,
    Object? coverCache = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$MetadataStateImpl(
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        localMetadata: null == localMetadata
            ? _value._localMetadata
            : localMetadata // ignore: cast_nullable_to_non_nullable
                  as Map<String, AudioMetadata>,
        coverCache: null == coverCache
            ? _value._coverCache
            : coverCache // ignore: cast_nullable_to_non_nullable
                  as Map<String, Uint8List>,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$MetadataStateImpl implements _MetadataState {
  const _$MetadataStateImpl({
    this.isLoading = false,
    final Map<String, AudioMetadata> localMetadata = const {},
    final Map<String, Uint8List> coverCache = const {},
    this.errorMessage,
  }) : _localMetadata = localMetadata,
       _coverCache = coverCache;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 已加载的本地音频元数据（文件路径 -> 元数据）
  final Map<String, AudioMetadata> _localMetadata;

  /// 已加载的本地音频元数据（文件路径 -> 元数据）
  @override
  @JsonKey()
  Map<String, AudioMetadata> get localMetadata {
    if (_localMetadata is EqualUnmodifiableMapView) return _localMetadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_localMetadata);
  }

  /// 封面缓存（URL -> Uint8List）
  final Map<String, Uint8List> _coverCache;

  /// 封面缓存（URL -> Uint8List）
  @override
  @JsonKey()
  Map<String, Uint8List> get coverCache {
    if (_coverCache is EqualUnmodifiableMapView) return _coverCache;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_coverCache);
  }

  /// 错误消息
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'MetadataState(isLoading: $isLoading, localMetadata: $localMetadata, coverCache: $coverCache, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MetadataStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(
              other._localMetadata,
              _localMetadata,
            ) &&
            const DeepCollectionEquality().equals(
              other._coverCache,
              _coverCache,
            ) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isLoading,
    const DeepCollectionEquality().hash(_localMetadata),
    const DeepCollectionEquality().hash(_coverCache),
    errorMessage,
  );

  /// Create a copy of MetadataState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MetadataStateImplCopyWith<_$MetadataStateImpl> get copyWith =>
      __$$MetadataStateImplCopyWithImpl<_$MetadataStateImpl>(this, _$identity);
}

abstract class _MetadataState implements MetadataState {
  const factory _MetadataState({
    final bool isLoading,
    final Map<String, AudioMetadata> localMetadata,
    final Map<String, Uint8List> coverCache,
    final String? errorMessage,
  }) = _$MetadataStateImpl;

  /// 是否正在加载
  @override
  bool get isLoading;

  /// 已加载的本地音频元数据（文件路径 -> 元数据）
  @override
  Map<String, AudioMetadata> get localMetadata;

  /// 封面缓存（URL -> Uint8List）
  @override
  Map<String, Uint8List> get coverCache;

  /// 错误消息
  @override
  String? get errorMessage;

  /// Create a copy of MetadataState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MetadataStateImplCopyWith<_$MetadataStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AudioMetadata {
  String get title => throw _privateConstructorUsedError;
  String get artist => throw _privateConstructorUsedError;
  String get album => throw _privateConstructorUsedError;
  Uint8List? get cover => throw _privateConstructorUsedError;

  /// Create a copy of AudioMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AudioMetadataCopyWith<AudioMetadata> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AudioMetadataCopyWith<$Res> {
  factory $AudioMetadataCopyWith(
    AudioMetadata value,
    $Res Function(AudioMetadata) then,
  ) = _$AudioMetadataCopyWithImpl<$Res, AudioMetadata>;
  @useResult
  $Res call({String title, String artist, String album, Uint8List? cover});
}

/// @nodoc
class _$AudioMetadataCopyWithImpl<$Res, $Val extends AudioMetadata>
    implements $AudioMetadataCopyWith<$Res> {
  _$AudioMetadataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AudioMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? cover = freezed,
  }) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            artist: null == artist
                ? _value.artist
                : artist // ignore: cast_nullable_to_non_nullable
                      as String,
            album: null == album
                ? _value.album
                : album // ignore: cast_nullable_to_non_nullable
                      as String,
            cover: freezed == cover
                ? _value.cover
                : cover // ignore: cast_nullable_to_non_nullable
                      as Uint8List?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AudioMetadataImplCopyWith<$Res>
    implements $AudioMetadataCopyWith<$Res> {
  factory _$$AudioMetadataImplCopyWith(
    _$AudioMetadataImpl value,
    $Res Function(_$AudioMetadataImpl) then,
  ) = __$$AudioMetadataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String artist, String album, Uint8List? cover});
}

/// @nodoc
class __$$AudioMetadataImplCopyWithImpl<$Res>
    extends _$AudioMetadataCopyWithImpl<$Res, _$AudioMetadataImpl>
    implements _$$AudioMetadataImplCopyWith<$Res> {
  __$$AudioMetadataImplCopyWithImpl(
    _$AudioMetadataImpl _value,
    $Res Function(_$AudioMetadataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AudioMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? artist = null,
    Object? album = null,
    Object? cover = freezed,
  }) {
    return _then(
      _$AudioMetadataImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        artist: null == artist
            ? _value.artist
            : artist // ignore: cast_nullable_to_non_nullable
                  as String,
        album: null == album
            ? _value.album
            : album // ignore: cast_nullable_to_non_nullable
                  as String,
        cover: freezed == cover
            ? _value.cover
            : cover // ignore: cast_nullable_to_non_nullable
                  as Uint8List?,
      ),
    );
  }
}

/// @nodoc

class _$AudioMetadataImpl implements _AudioMetadata {
  const _$AudioMetadataImpl({
    required this.title,
    required this.artist,
    required this.album,
    this.cover,
  });

  @override
  final String title;
  @override
  final String artist;
  @override
  final String album;
  @override
  final Uint8List? cover;

  @override
  String toString() {
    return 'AudioMetadata(title: $title, artist: $artist, album: $album, cover: $cover)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AudioMetadataImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.artist, artist) || other.artist == artist) &&
            (identical(other.album, album) || other.album == album) &&
            const DeepCollectionEquality().equals(other.cover, cover));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    title,
    artist,
    album,
    const DeepCollectionEquality().hash(cover),
  );

  /// Create a copy of AudioMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AudioMetadataImplCopyWith<_$AudioMetadataImpl> get copyWith =>
      __$$AudioMetadataImplCopyWithImpl<_$AudioMetadataImpl>(this, _$identity);
}

abstract class _AudioMetadata implements AudioMetadata {
  const factory _AudioMetadata({
    required final String title,
    required final String artist,
    required final String album,
    final Uint8List? cover,
  }) = _$AudioMetadataImpl;

  @override
  String get title;
  @override
  String get artist;
  @override
  String get album;
  @override
  Uint8List? get cover;

  /// Create a copy of AudioMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AudioMetadataImplCopyWith<_$AudioMetadataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
