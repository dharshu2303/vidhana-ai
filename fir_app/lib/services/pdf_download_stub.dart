import 'dart:typed_data';

/// Stub for non-web platforms. On mobile/desktop, we use Printing.layoutPdf
/// instead, so this should never actually be called.
void downloadPdfWeb(Uint8List bytes, String filename) {
  throw UnsupportedError('downloadPdfWeb is only supported on Flutter Web');
}
