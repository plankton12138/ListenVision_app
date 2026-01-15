import 'package:file_picker/file_picker.dart';

class FilePickerService {
  // select file from device storage
  Future<String?> pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    return result?.files.single.path;// return path of selected file
  }
}