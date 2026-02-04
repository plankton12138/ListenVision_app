import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/routes/router.dart';

/// App 入口，由 ProviderScope 包裹
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'ListenVision',
        routerConfig: router,
      ),
    );
  }
}
