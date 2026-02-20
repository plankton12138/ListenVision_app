import 'package:file_selector/file_selector.dart';

/// 文件选择服务
///
/// 封装 file_selector 功能，提供音频文件选择接口
class FilePickerService {
  /// 音频文件类型过滤器
  static const XTypeGroup audioTypeGroup = XTypeGroup(
    label: 'audio',
    mimeTypes: <String>[
      'audio/mpeg',      // MP3
      'audio/mp4',       // M4A
      'audio/x-m4a',     // M4A
      'audio/flac',      // FLAC
      'audio/wav',       // WAV
      'audio/x-wav',     // WAV
      'audio/ogg',       // OGG
    ],
    extensions: <String>[
      'mp3',
      'm4a',
      'flac',
      'wav',
      'ogg',
    ],
    uniformTypeIdentifiers: <String>[
      'public.audio',
      'com.apple.m4a-audio',
      'public.mp3',
      'public.flac-audio',
    ],
  );

  /// 从设备存储选择音频文件
  ///
  /// Web 平台上无法获得真实可读的本地路径，因此返回 XFile，调用方可 readAsBytes()。
  Future<XFile?> pickAudioFile() async {
    const typeGroup = audioTypeGroup;
    return await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );
  }
}
