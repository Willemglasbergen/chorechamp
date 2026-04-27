import 'package:file_picker/file_picker.dart';

import 'image_picker_bytes_types.dart';

Future<PickedImageBytes?> pickSingleImageBytes() async {
  final res = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true,
  );
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.first;
  final data = f.bytes;
  if (data == null) return null;
  final ext = (f.extension ?? '').toLowerCase();
  final mime = ext == 'png'
      ? 'image/png'
      : ext == 'webp'
          ? 'image/webp'
          : 'image/jpeg';
  return PickedImageBytes(
    bytes: data,
    fileName: f.name,
    mimeType: mime,
  );
}
