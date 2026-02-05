// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_music_viewmodel.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$localMusicRepositoryHash() =>
    r'86694a3890716c94aee4dea42cbdb2a3a5389cd1';

/// Provider 定义
///
/// Copied from [localMusicRepository].
@ProviderFor(localMusicRepository)
final localMusicRepositoryProvider =
    AutoDisposeProvider<LocalMusicRepository>.internal(
      localMusicRepository,
      name: r'localMusicRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localMusicRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LocalMusicRepositoryRef = AutoDisposeProviderRef<LocalMusicRepository>;
String _$localMusicViewModelHash() =>
    r'e5f15fa9e2df19b29494039b3b02a248f49b7320';

/// 本地音乐 ViewModel
///
/// 负责本地音乐歌单的管理和导入
///
/// Copied from [LocalMusicViewModel].
@ProviderFor(LocalMusicViewModel)
final localMusicViewModelProvider =
    AutoDisposeNotifierProvider<LocalMusicViewModel, LocalMusicState>.internal(
      LocalMusicViewModel.new,
      name: r'localMusicViewModelProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$localMusicViewModelHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LocalMusicViewModel = AutoDisposeNotifier<LocalMusicState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
