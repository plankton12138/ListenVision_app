// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'queue_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$QueueState {
  /// 播放队列（本地和在线混合）
  List<PlayableAudio> get queue => throw _privateConstructorUsedError;

  /// 本地音频列表
  List<LocalAudio> get localAudios => throw _privateConstructorUsedError;

  /// 当前播放索引
  int get currentIndex => throw _privateConstructorUsedError;

  /// 是否正在加载
  bool get isLoading => throw _privateConstructorUsedError;

  /// 错误消息
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Create a copy of QueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QueueStateCopyWith<QueueState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QueueStateCopyWith<$Res> {
  factory $QueueStateCopyWith(
    QueueState value,
    $Res Function(QueueState) then,
  ) = _$QueueStateCopyWithImpl<$Res, QueueState>;
  @useResult
  $Res call({
    List<PlayableAudio> queue,
    List<LocalAudio> localAudios,
    int currentIndex,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class _$QueueStateCopyWithImpl<$Res, $Val extends QueueState>
    implements $QueueStateCopyWith<$Res> {
  _$QueueStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queue = null,
    Object? localAudios = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            queue: null == queue
                ? _value.queue
                : queue // ignore: cast_nullable_to_non_nullable
                      as List<PlayableAudio>,
            localAudios: null == localAudios
                ? _value.localAudios
                : localAudios // ignore: cast_nullable_to_non_nullable
                      as List<LocalAudio>,
            currentIndex: null == currentIndex
                ? _value.currentIndex
                : currentIndex // ignore: cast_nullable_to_non_nullable
                      as int,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$QueueStateImplCopyWith<$Res>
    implements $QueueStateCopyWith<$Res> {
  factory _$$QueueStateImplCopyWith(
    _$QueueStateImpl value,
    $Res Function(_$QueueStateImpl) then,
  ) = __$$QueueStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<PlayableAudio> queue,
    List<LocalAudio> localAudios,
    int currentIndex,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class __$$QueueStateImplCopyWithImpl<$Res>
    extends _$QueueStateCopyWithImpl<$Res, _$QueueStateImpl>
    implements _$$QueueStateImplCopyWith<$Res> {
  __$$QueueStateImplCopyWithImpl(
    _$QueueStateImpl _value,
    $Res Function(_$QueueStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? queue = null,
    Object? localAudios = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$QueueStateImpl(
        queue: null == queue
            ? _value._queue
            : queue // ignore: cast_nullable_to_non_nullable
                  as List<PlayableAudio>,
        localAudios: null == localAudios
            ? _value._localAudios
            : localAudios // ignore: cast_nullable_to_non_nullable
                  as List<LocalAudio>,
        currentIndex: null == currentIndex
            ? _value.currentIndex
            : currentIndex // ignore: cast_nullable_to_non_nullable
                  as int,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$QueueStateImpl implements _QueueState {
  const _$QueueStateImpl({
    final List<PlayableAudio> queue = const [],
    final List<LocalAudio> localAudios = const [],
    this.currentIndex = -1,
    this.isLoading = false,
    this.errorMessage,
  }) : _queue = queue,
       _localAudios = localAudios;

  /// 播放队列（本地和在线混合）
  final List<PlayableAudio> _queue;

  /// 播放队列（本地和在线混合）
  @override
  @JsonKey()
  List<PlayableAudio> get queue {
    if (_queue is EqualUnmodifiableListView) return _queue;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_queue);
  }

  /// 本地音频列表
  final List<LocalAudio> _localAudios;

  /// 本地音频列表
  @override
  @JsonKey()
  List<LocalAudio> get localAudios {
    if (_localAudios is EqualUnmodifiableListView) return _localAudios;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_localAudios);
  }

  /// 当前播放索引
  @override
  @JsonKey()
  final int currentIndex;

  /// 是否正在加载
  @override
  @JsonKey()
  final bool isLoading;

  /// 错误消息
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'QueueState(queue: $queue, localAudios: $localAudios, currentIndex: $currentIndex, isLoading: $isLoading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QueueStateImpl &&
            const DeepCollectionEquality().equals(other._queue, _queue) &&
            const DeepCollectionEquality().equals(
              other._localAudios,
              _localAudios,
            ) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_queue),
    const DeepCollectionEquality().hash(_localAudios),
    currentIndex,
    isLoading,
    errorMessage,
  );

  /// Create a copy of QueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QueueStateImplCopyWith<_$QueueStateImpl> get copyWith =>
      __$$QueueStateImplCopyWithImpl<_$QueueStateImpl>(this, _$identity);
}

abstract class _QueueState implements QueueState {
  const factory _QueueState({
    final List<PlayableAudio> queue,
    final List<LocalAudio> localAudios,
    final int currentIndex,
    final bool isLoading,
    final String? errorMessage,
  }) = _$QueueStateImpl;

  /// 播放队列（本地和在线混合）
  @override
  List<PlayableAudio> get queue;

  /// 本地音频列表
  @override
  List<LocalAudio> get localAudios;

  /// 当前播放索引
  @override
  int get currentIndex;

  /// 是否正在加载
  @override
  bool get isLoading;

  /// 错误消息
  @override
  String? get errorMessage;

  /// Create a copy of QueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QueueStateImplCopyWith<_$QueueStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
