import 'image_picker_bytes_types.dart';

import 'image_picker_bytes_io.dart'
    if (dart.library.html) 'image_picker_bytes_web.dart' as impl;

Future<PickedImageBytes?> pickSingleImageBytes() => impl.pickSingleImageBytes();
