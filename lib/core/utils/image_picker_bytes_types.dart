import 'dart:typed_data';

class PickedImageBytes {
  final Uint8List bytes;
  final String? fileName;
  final String? mimeType;
  const PickedImageBytes({required this.bytes, this.fileName, this.mimeType});
}
