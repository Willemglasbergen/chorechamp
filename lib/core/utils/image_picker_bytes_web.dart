// Web implementation: use native <input type="file"> and attach to DOM for reliability
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:html' as html;
import 'dart:typed_data';

import 'image_picker_bytes_types.dart';

Future<PickedImageBytes?> pickSingleImageBytes() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false
    ..style.display = 'none';

  final completer = Completer<PickedImageBytes?>();

  void cleanup() {
    try {
      input.remove();
    } catch (_) {}
  }

  void done(PickedImageBytes? value) {
    if (!completer.isCompleted) completer.complete(value);
    cleanup();
  }

  // Append to DOM to ensure onChange reliably fires in all browsers/environments
  html.document.body?.append(input);

  // Ensure selecting the same file twice still triggers onChange by resetting the value
  input.value = '';

  Future<void> readFile(html.File file) async {
    // Try ArrayBuffer first
    final reader = html.FileReader();
    try {
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;
      final result = reader.result;
      Uint8List? bytes;
      if (result is ByteBuffer) {
        bytes = Uint8List.view(result);
      } else if (result is Uint8List) {
        bytes = result;
      } else if (result is List<int>) {
        bytes = Uint8List.fromList(result);
      }
      if (bytes != null) {
        developer.log(
            'File read complete via ArrayBuffer: name=${file.name} type=${file.type} bytes=${bytes.length}',
            name: 'ImagePickerWeb');
        done(PickedImageBytes(
            bytes: bytes, fileName: file.name, mimeType: file.type));
        return;
      }
    } catch (e) {
      developer.log('ArrayBuffer read error: $e', name: 'ImagePickerWeb');
    }

    // Fallback: Data URL, then decode base64
    try {
      final reader2 = html.FileReader();
      reader2.readAsDataUrl(file);
      await reader2.onLoadEnd.first;
      final dataUrl = reader2.result;
      if (dataUrl is String && dataUrl.startsWith('data:')) {
        final comma = dataUrl.indexOf(',');
        if (comma != -1) {
          final meta = dataUrl.substring(5, comma); // e.g., image/png;base64
          final base64Part = dataUrl.substring(comma + 1);
          final bytes = base64.decode(base64Part);
          final mimeType = meta.split(';').firstOrNull ?? file.type;
          developer.log(
              'File read complete via DataURL: name=${file.name} type=$mimeType bytes=${bytes.length}',
              name: 'ImagePickerWeb');
          done(PickedImageBytes(
              bytes: Uint8List.fromList(bytes),
              fileName: file.name,
              mimeType: mimeType));
          return;
        }
      }
    } catch (e) {
      developer.log('DataURL read error: $e', name: 'ImagePickerWeb');
    }

    // If all reading methods failed
    done(null);
  }

  input.onChange.first.then((event) async {
    developer.log('File input change event fired', name: 'ImagePickerWeb');
    final files = input.files;
    if (files == null || files.isEmpty) {
      done(null);
      return;
    }
    final file = files.first;
    await readFile(file);
  });

  input.onError.first.then((event) {
    developer.log('File input error: $event', name: 'ImagePickerWeb');
    done(null);
  });

  // Trigger the chooser on next microtask to ensure listeners are attached
  scheduleMicrotask(() {
    try {
      input.click();
    } catch (e) {
      developer.log('File input click error: $e', name: 'ImagePickerWeb');
      done(null);
    }
  });

  return completer.future;
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
