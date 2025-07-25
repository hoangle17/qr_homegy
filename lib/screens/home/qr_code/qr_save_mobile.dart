import 'dart:typed_data';

// Stub functions for mobile platform
// These functions are not used on mobile as we use Share.shareXFiles instead
void saveQrWeb(Uint8List bytes) {
  // Not used on mobile
}

void shareQrWeb(Uint8List bytes) {
  // Not used on mobile
}

void shareMultipleQrWeb(List<Uint8List> qrImages, List<String> fileNames) {
  // Not used on mobile
}

void savePdfWeb(Uint8List pdfBytes, String fileName) {
  // Not used on mobile
} 