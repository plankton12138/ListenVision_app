import 'package:file_picker/file_picker.dart';

/// 文件选择服务
///
/// 封装 file_picker 功能，提供音频文件选择接口
/// 从 utils/file_picker.dart 迁移到 core/utils/
class FilePickerService {
  /// 从设备存储选择音频文件
  ///
  /// 返回所选文件的路径，取消选择时返回 null
  Future<String?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    return result?.files.single.path; // 返回所选文件的路径
  }
}
