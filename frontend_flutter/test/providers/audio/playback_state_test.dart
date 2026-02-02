import 'package:flutter_test/flutter_test.dart';
import 'package:demo/presentation/providers/audio/playback_state.dart';

void main() {
  group('PlaybackState', () {
    test('默认构造函数应该创建初始状态', () {
      final state = PlaybackState();

      expect(state.isPlaying, false);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isLoading, false);
      expect(state.position, Duration.zero);
      expect(state.duration, null);
      expect(state.errorMessage, null);
    });

    test('构造函数应该接受所有参数', () {
      final state = PlaybackState(
        isPlaying: true,
        isPaused: false,
        isCompleted: false,
        isLoading: true,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
        errorMessage: '测试错误',
      );

      expect(state.isPlaying, true);
      expect(state.isPaused, false);
      expect(state.isCompleted, false);
      expect(state.isLoading, true);
      expect(state.position, const Duration(seconds: 30));
      expect(state.duration, const Duration(minutes: 3));
      expect(state.errorMessage, '测试错误');
    });

    test('copyWith 应该只更新指定字段', () {
      final original = PlaybackState(
        isPlaying: true,
        isPaused: false,
        isCompleted: false,
        isLoading: true,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
        errorMessage: '原始错误',
      );

      final updated = original.copyWith(isPlaying: false);

      expect(updated.isPlaying, false);
      expect(updated.isPaused, false); // 未更新
      expect(updated.isCompleted, false); // 未更新
      expect(updated.isLoading, true); // 未更新
      expect(updated.position, const Duration(seconds: 30)); // 未更新
      expect(updated.duration, const Duration(minutes: 3)); // 未更新
      expect(updated.errorMessage, '原始错误'); // 未更新
    });

    test('copyWith 应该可以更新多个字段', () {
      final original = PlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
      );

      final updated = original.copyWith(
        isPlaying: false,
        isPaused: true,
        position: const Duration(seconds: 45),
      );

      expect(updated.isPlaying, false);
      expect(updated.isPaused, true);
      expect(updated.position, const Duration(seconds: 45));
    });

    test('copyWithNoError 可以清除错误消息', () {
      final original = PlaybackState(
        errorMessage: '错误消息',
      );

      final updated = original.copyWithNoError();

      expect(updated.errorMessage, null);
      // 其他字段应保持不变
      expect(updated.isPlaying, original.isPlaying);
      expect(updated.position, original.position);
    });

    test('toString 应该返回格式化的字符串', () {
      final state = PlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
      );

      final str = state.toString();

      expect(str, contains('isPlaying: true'));
      expect(str, contains('position: 0:00:30.000000'));
      expect(str, contains('duration: 0:03:00.000000'));
    });

    test('相等性检查: 相同状态应该相等', () {
      final state1 = PlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
      );

      final state2 = PlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('相等性检查: 不同状态应该不相等', () {
      final state1 = PlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
      );

      final state2 = PlaybackState(
        isPlaying: false,
        position: const Duration(seconds: 30),
      );

      expect(state1, isNot(equals(state2)));
    });

    test('相等性检查: 所有字段都影响相等性', () {
      final baseState = PlaybackState(
        isPlaying: true,
        isPaused: false,
        isCompleted: false,
        isLoading: false,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3),
        errorMessage: '错误',
      );

      // 测试每个字段
      expect(
        baseState == baseState.copyWith(isPlaying: false),
        false,
        reason: 'isPlaying 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(isPaused: true),
        false,
        reason: 'isPaused 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(isCompleted: true),
        false,
        reason: 'isCompleted 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(isLoading: true),
        false,
        reason: 'isLoading 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(position: const Duration(seconds: 31)),
        false,
        reason: 'position 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(duration: const Duration(minutes: 4)),
        false,
        reason: 'duration 应该影响相等性',
      );

      expect(
        baseState == baseState.copyWith(errorMessage: '其他错误'),
        false,
        reason: 'errorMessage 应该影响相等性',
      );
    });
  });
}
