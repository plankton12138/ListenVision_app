import 'package:flutter/material.dart';
import 'empty_state.dart';

/// 异步构建器组件
///
/// 统一处理异步操作的状态显示：加载中、成功、错误
class AsyncBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(T data) builder;
  final Widget Function()? loadingBuilder;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget Function()? emptyBuilder;

  const AsyncBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  /// 从 Future 创建
  factory AsyncBuilder.future({
    Key? key,
    required Future<T>? future,
    required Widget Function(T data) builder,
    Widget Function()? loadingBuilder,
    Widget Function(Object error, StackTrace? stackTrace)? errorBuilder,
    Widget Function()? emptyBuilder,
    T? initialData,
  }) {
    return AsyncBuilder<T>(
      key: key,
      snapshot: AsyncSnapshot.withError(
        ConnectionState.waiting,
        UnimplementedError(),
      ),
      builder: builder,
      loadingBuilder: loadingBuilder,
      errorBuilder: errorBuilder,
      emptyBuilder: emptyBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
        return loadingBuilder?.call() ?? _defaultLoading(context);

      case ConnectionState.active:
      case ConnectionState.done:
        if (snapshot.hasError) {
          return errorBuilder?.call(
                snapshot.error!,
                snapshot.stackTrace,
              ) ??
              _defaultError(context, snapshot.error!, snapshot.stackTrace);
        }

        if (snapshot.hasData) {
          final data = snapshot.data!;
          // 检查是否为空集合
          if (data is Iterable && data.isEmpty) {
            return emptyBuilder?.call() ?? _defaultEmpty(context);
          }
          if (data is Map && data.isEmpty) {
            return emptyBuilder?.call() ?? _defaultEmpty(context);
          }
          if (data is String && data.isEmpty) {
            return emptyBuilder?.call() ?? _defaultEmpty(context);
          }
          return builder(data);
        }

        return emptyBuilder?.call() ?? _defaultEmpty(context);
    }
  }

  Widget _defaultLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _defaultError(BuildContext context, Object error, StackTrace? stackTrace) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultEmpty(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无数据', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

/// 列表异步构建器
///
/// 专用于列表数据的异步构建器
class AsyncListBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<List<T>> snapshot;
  final Widget Function(T item, int index) itemBuilder;
  final Widget Function()? loadingBuilder;
  final Widget Function(Object error)? errorBuilder;
  final Widget Function()? emptyBuilder;
  final EdgeInsets? padding;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  const AsyncListBuilder({
    super.key,
    required this.snapshot,
    required this.itemBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.padding,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
  });

  @override
  Widget build(BuildContext context) {
    switch (snapshot.connectionState) {
      case ConnectionState.none:
      case ConnectionState.waiting:
        return loadingBuilder?.call() ?? const _LoadingList();

      case ConnectionState.active:
      case ConnectionState.done:
        if (snapshot.hasError) {
          return errorBuilder?.call(snapshot.error!) ?? _ErrorList(error: snapshot.error!);
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return emptyBuilder?.call() ?? const _EmptyList();
        }

        return ListView.builder(
          keyboardDismissBehavior: keyboardDismissBehavior,
          padding: padding,
          itemCount: items.length,
          itemBuilder: (context, index) => itemBuilder(items[index], index),
        );
    }
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(),
        );
      },
    );
  }
}

class _ErrorList extends StatelessWidget {
  final Object error;

  const _ErrorList({required this.error});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
        const SizedBox(height: 16),
        Text(
          error.toString(),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return const EmptyState.list();
  }
}

/// 骨架屏加载器
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height ?? 16,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: _ShimmerAnimation(),
    );
  }
}

class _ShimmerAnimation extends StatefulWidget {
  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: const [0.4, 0.5, 0.6],
              transform: _SlidingGradientTransform(
                slidePercent: _animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(color: Colors.grey[300]),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
