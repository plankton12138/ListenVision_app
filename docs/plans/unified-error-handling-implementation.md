# 统一错误提示风格实现方案

**方案制定日期**: 2026-02-16
**关联主计划**: architecture-compliance-fix-plan.md
**优先级**: P1

---
## 一、目标

统一应用内的所有错误提示风格，替换现有的192处分散的`ScaffoldMessenger.showSnackBar()`调用，使用已创建的`ErrorUIHandler`组件提供一致的用户体验。

## 二、当前问题分析

### 2.1 提示风格不统一
报告中标识了192处直接使用`ScaffoldMessenger.of(context).showSnackBar()`的调用，存在多种样式：

```dart
// 样式1：简单文本
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('播放失败: $e')),
);

// 样式2：带颜色
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
);

// 样式3：带操作
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('已添加到下一首: ${audio.title}'),
    action: SnackBarAction(label: '撤销', onPressed: () {}),
  ),
);

// 样式4：英文提示
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('No previous track')),
);

// 样式5：详细信息
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('导入失败: ${e.toString()}')),
);
```

### 2.2 已有组件未充分利用
系统已经创建了统一的错误处理入口：
- `lib/presentation/utils/error_ui_handler.dart` - 统一UI处理
- `lib/core/utils/error_handler.dart` - 错误分类处理

但现有代码未迁移至这些组件。

## 三、解决方案设计

### 3.1 核心思路
1. 全面替换现有的`showSnackBar`调用为`ErrorUIHandler`方法
2. 根据错误类型和严重程度选择合适的提示方式
3. 提供一致的视觉风格和交互体验

### 3.2 实现架构
```
错误发生 -> ErrorUIHandler -> 错误分类 -> 选择提示方式 -> 显示统一UI
```

## 四、详细实现步骤

### 4.1 增强ErrorUIHandler

**文件**: `lib/presentation/utils/error_ui_handler.dart`

增强现有功能：
```dart
import 'package:flutter/material.dart';
import '../../core/utils/error_handler.dart';
import '../../core/utils/logger.dart';

class ErrorUIHandler {
  /// 显示错误Snackbar
  static void showError(BuildContext context, dynamic error, {String? title}) {
    final errorMessage = ErrorHandler.getErrorMessage(error);
    final displayTitle = title ?? ErrorHandler.getErrorTitle(error);
    
    // 根据错误类型确定颜色
    final backgroundColor = _getBackgroundColor(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(displayTitle != null 
            ? '$displayTitle: $errorMessage' 
            : errorMessage),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: '详情',
          onPressed: () => showErrorDialog(context, error, title: title),
        ),
      ),
    );
  }
  
  /// 显示成功Snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  /// 显示警告Snackbar
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  /// 显示错误对话框
  static void showErrorDialog(BuildContext context, dynamic error, {String? title}) {
    final errorMessage = ErrorHandler.getErrorMessage(error);
    final displayTitle = title ?? ErrorHandler.getErrorTitle(error) ?? '错误';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(displayTitle),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示确认对话框
  static Future<bool> showConfirmDialog(
    BuildContext context, 
    String title, 
    String message,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('确认'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
  
  /// 根据错误类型获取背景颜色
  static Color _getBackgroundColor(dynamic error) {
    if (ErrorHandler.isNetworkError(error)) {
      return Colors.blue; // 网络错误用蓝色
    } else if (ErrorHandler.isValidationError(error)) {
      return Colors.orange; // 验证错误用橙色
    } else {
      return Colors.red; // 其他错误用红色
    }
  }
  
  /// 显示Toast提示（轻量级提示）
  static void showToast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    
    // 先隐藏当前的snackbar
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

### 4.2 创建错误类型枚举

**新建文件**: `lib/core/models/error_type.dart`

```dart
enum ErrorType {
  network,        // 网络错误
  validation,     // 验证错误
  permission,     // 权限错误
  notFound,       // 未找到
  conflict,       // 冲突
  server,         // 服务器错误
  unknown,        // 未知错误
}

extension ErrorTypeExtension on ErrorType {
  String get title {
    switch (this) {
      case ErrorType.network:
        return '网络错误';
      case ErrorType.validation:
        return '输入错误';
      case ErrorType.permission:
        return '权限不足';
      case ErrorType.notFound:
        return '未找到';
      case ErrorType.conflict:
        return '冲突';
      case ErrorType.server:
        return '服务器错误';
      case ErrorType.unknown:
        return '未知错误';
    }
  }
  
  Color get color {
    switch (this) {
      case ErrorType.network:
        return Colors.blue;
      case ErrorType.validation:
        return Colors.orange;
      case ErrorType.permission:
        return Colors.purple;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.conflict:
        return Colors.yellow;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.unknown:
        return Colors.black;
    }
  }
}
```

### 4.3 批量替换现有调用

由于存在192处需要替换的调用，这里提供几种典型替换示例：

#### 4.3.1 网络错误提示替换
**原代码**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('网络连接失败')),
);
```

**新代码**:
```dart
ErrorUIHandler.showError(context, NetworkException('网络连接失败'));
```

#### 4.3.2 成功提示替换
**原代码**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('已添加到下一首: ${audio.title}')),
);
```

**新代码**:
```dart
ErrorUIHandler.showSuccess(context, '已添加到下一首: ${audio.title}');
```

#### 4.3.3 验证错误替换
**原代码**:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('请输入有效的邮箱地址'), backgroundColor: Colors.orange),
);
```

**新代码**:
```dart
ErrorUIHandler.showWarning(context, '请输入有效的邮箱地址');
```

## 五、迁移策略

### 5.1 分批迁移
由于涉及192处修改，建议采用分批迁移策略：

1. **第一批**: 核心功能模块(播放、下载、同步) - 50处
2. **第二批**: 用户界面模块(设置、个人资料) - 40处
3. **第三批**: 数据管理模块(搜索、收藏) - 40处
4. **第四批**: 其他辅助模块 - 62处

### 5.2 自动化脚本辅助
编写简单的正则表达式脚本来辅助识别和替换常见的模式：

```bash
# 查找所有showSnackBar调用
grep -r "showSnackBar" lib/

# 查找特定模式
grep -r "ScaffoldMessenger.of.*showSnackBar" lib/
```

## 六、测试方案

### 6.1 单元测试

**测试文件**: `test/presentation/utils/error_ui_handler_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import '../../../lib/presentation/utils/error_ui_handler.dart';
import '../../../lib/core/utils/error_handler.dart';

void main() {
  group('ErrorUIHandler', () {
    late BuildContext mockContext;
    
    setUp(() {
      // 创建测试用的BuildContext
      final widget = MaterialApp(home: Scaffold(body: Container()));
      final renderer = TestWidgetsFlutterBinding.instance;
      mockContext = renderer.attachRootWidget(widget);
    });
    
    test('应该显示错误Snackbar', () {
      // 这个测试主要用于编译检查，实际UI测试需要用widget测试
      expect(() => ErrorUIHandler.showError(mockContext, '测试错误'), 
            returnsNormally);
    });
    
    test('应该显示成功Snackbar', () {
      expect(() => ErrorUIHandler.showSuccess(mockContext, '操作成功'), 
            returnsNormally);
    });
    
    test('应该显示警告Snackbar', () {
      expect(() => ErrorUIHandler.showWarning(mockContext, '警告信息'), 
            returnsNormally);
    });
  });
}
```

### 6.2 Widget测试

**测试文件**: `test/widget/error_ui_handler_widget_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../lib/presentation/utils/error_ui_handler.dart';

void main() {
  group('ErrorUIHandler Widget Tests', () {
    testWidgets('显示错误Snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => ErrorUIHandler.showError(context, '测试错误'),
                  child: Text('显示错误'),
                );
              },
            ),
          ),
        ),
      );
      
      // 点击按钮
      await tester.tap(find.text('显示错误'));
      await tester.pumpAndSettle();
      
      // 验证Snackbar显示
      expect(find.textContaining('测试错误'), findsOneWidget);
    });
    
    testWidgets('显示成功Snackbar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => ErrorUIHandler.showSuccess(context, '操作成功'),
                  child: Text('显示成功'),
                );
              },
            ),
          ),
        ),
      );
      
      await tester.tap(find.text('显示成功'));
      await tester.pumpAndSettle();
      
      expect(find.text('操作成功'), findsOneWidget);
    });
  });
}
```

## 七、质量保证措施

### 7.1 代码审查清单
- [ ] 所有新的错误提示都使用ErrorUIHandler
- [ ] 错误消息具有描述性且对用户友好
- [ ] 不同类型的错误使用不同的视觉表示
- [ ] 成功和警告消息也使用统一的样式
- [ ] 保持与现有设计语言的一致性

### 7.2 国际化考虑
- 错误消息应支持多语言
- 可以结合flutter_i18n等库实现国际化

### 7.3 可访问性
- 确保Snackbar消息可以通过屏幕阅读器读取
- 提供足够的对比度以满足可访问性标准

## 八、部署验证清单

- [ ] ErrorUIHandler功能完整性和正确性验证
- [ ] 错误类型分类准确性验证
- [ ] 至少迁移20%的现有showSnackBar调用作为试点
- [ ] UI测试通过，确保提示显示正确
- [ ] 不同错误类型的视觉区分明显
- [ ] 性能测试(Snackbar显示延迟<100ms)
- [ ] 兼容性测试(Android/iOS/Web)

---
**方案版本**: v1.0
**预计开发时间**: 8小时
**预计测试时间**: 4小时