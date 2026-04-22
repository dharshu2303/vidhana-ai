import 'dart:typed_data';

/// Stub for platform-specific PDF saving.
void savePdf(Uint8List bytes, String filename) {
  throw UnsupportedError('savePdf is not implemented on this platform');
}
