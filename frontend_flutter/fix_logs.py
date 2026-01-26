import re
import sys

def determine_log_level(message):
    """根据消息内容确定日志级别"""
    if any(word in message.lower() for word in ['error', '错误', '失败', 'failed', 'exception', '异常']):
        return 'error'
    elif any(word in message.lower() for word in ['warn', '警告', 'warning', '超时', 'timeout']):
        return 'warn'
    elif any(word in message.lower() for word in ['开始', '启动', 'loaded', '完成', '成功', 'started', '已', '保存', '添加', '删除', '更新']):
        return 'info'
    else:
        return 'debug'

def extract_tag_from_context(content, pos):
    """从上下文中提取标签（通常是类名）"""
    # 查找最近的 class 定义
    class_match = re.search(r'class\s+(\w+)', content[:pos])
    if class_match:
        return class_match.group(1)
    return 'App'

def process_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 添加 import（如果还没有）
    if 'import \'package:demo/core/utils/app_logger.dart\';' not in content:
        # 在最后一个 import 后添加
        import_match = re.search(r"import\s+['\"]([^'\"]+)['\"]\s*;", content)
        if import_match:
            last_import_end = import_match.end()
            # 找到最后一个 import 的位置
            for match in re.finditer(r"import\s+['\"]([^'\"]+)['\"]\s*;", content):
                last_import_end = match.end()
            content = content[:last_import_end] + "\nimport 'package:demo/core/utils/app_logger.dart';" + content[last_import_end:]

    modified = False

    # 模式1: debugPrint('【Tag】xxx') - 带标签
    def replace_with_tag(match):
        nonlocal modified
        modified = True
        full_content = match.group(0)
        tag_match = re.search(r'【(.+?)】', full_content)
        if not tag_match:
            return full_content

        tag = tag_match.group(1)
        message = full_content[tag_match.end():]
        message = message.lstrip("'").rstrip("')")

        level = determine_log_level(message)
        return f"AppLogger.{level}('{tag}', '{message}')"

    content = re.sub(r"debugPrint\('【(.+?)】(.+?)'\)", replace_with_tag, content)

    # 模式2: debugPrint('xxx') - 不带标签，使用类名作为标签
    def replace_without_tag(match):
        nonlocal modified
        modified = True
        full_match = match.group(0)
        message = match.group(1)

        # 从文件中提取类名
        tag = extract_tag_from_context(content, match.start())
        level = determine_log_level(message)
        return f"AppLogger.{level}('{tag}', '{message}')"

    # 匹配 debugPrint('任意内容') 但不包含【】
    content = re.sub(r"debugPrint\('((?!【).+?)'\)", replace_without_tag, content)

    # 模式3: debugPrint("xxx") - 双引号
    def replace_double_quote(match):
        nonlocal modified
        modified = True
        full_match = match.group(0)
        message = match.group(1)

        tag = extract_tag_from_context(content, match.start())
        level = determine_log_level(message)
        return f'AppLogger.{level}(\'{tag}\', "{message}")'

    content = re.sub(r'debugPrint\("((?!【).+?)"\)', replace_double_quote, content)

    # 模式4: debugPrint('【Tag】xxx $变量') - 带变量插值
    def replace_with_interpolation(match):
        nonlocal modified
        modified = True
        full_content = match.group(0)

        # 提取标签
        tag_match = re.search(r'【(.+?)】', full_content)
        if tag_match:
            tag = tag_match.group(1)
            message_part = full_content[tag_match.end():]
        else:
            tag = extract_tag_from_context(content, match.start())
            message_part = full_content.replace("debugPrint('", '').rstrip("')")

        # 清理消息部分
        message_part = message_part.strip()

        level = determine_log_level(message_part)
        return f"AppLogger.{level}('{tag}', '{message_part}')"

    # 使用更宽松的模式匹配带变量的情况
    content = re.sub(r"debugPrint\('【[^】]+】[^\']*'\)", replace_with_interpolation, content)

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Processed: {file_path}")
        return True
    else:
        print(f"Skipped (no changes): {file_path}")
        return False

if __name__ == '__main__':
    # 处理所有包含 debugPrint 的文件
    files_to_process = [
        'lib/presentation/providers/play_history/play_history_provider.dart',
        'lib/presentation/providers/playlist/playlist_provider.dart',
        'lib/core/config/app_config.dart',
        'lib/presentation/providers/audio/playback_queue.dart',
        'lib/presentation/providers/audio/unified_playlist_manager.dart',
        'lib/presentation/providers/audio/playback_state_manager.dart',
        'lib/core/utils/error_handler.dart',
        'lib/presentation/pages/search_page.dart',
        'lib/presentation/pages/explore_page.dart',
        'lib/presentation/pages/playlist_detail_page.dart',
        'lib/presentation/providers/playlist/playlist_crud_provider.dart',
        'lib/presentation/pages/play_history_page.dart',
        'lib/presentation/providers/download/download_manager.dart',
        'lib/presentation/pages/login_page.dart',
        'lib/presentation/widgets/audio_info.dart',
        'lib/presentation/providers/theme/theme_provider.dart',
        'lib/presentation/providers/audio/audio_metadata_provider.dart',
        'lib/presentation/providers/bilibili/qr_login_provider.dart',
        'lib/presentation/providers/bilibili/cache_provider.dart',
        'lib/core/utils/metadata_writer.dart',
        'lib/core/network/api_client.dart',
        'lib/presentation/providers/favorites/favorites_provider.dart',
        'lib/presentation/providers/audio/audio_playlist_provider.dart',
        'lib/presentation/providers/audio/now_playing_provider.dart',
        'lib/presentation/providers/bilibili/auth_provider.dart',
        'lib/core/base/base_provider.dart',
    ]

    processed = 0
    for file_path in files_to_process:
        try:
            if process_file(file_path):
                processed += 1
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

    print(f"\nTotal processed: {processed}/{len(files_to_process)}")
