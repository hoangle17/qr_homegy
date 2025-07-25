import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void saveQrWeb(Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'qr_code.png')
    ..click();
  html.Url.revokeObjectUrl(url);
}

void shareQrWeb(Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Tạo link chia sẻ
  html.AnchorElement(href: url)
    ..setAttribute('download', 'qr_code.png')
    ..target = '_blank'
    ..click();
  
  html.Url.revokeObjectUrl(url);
}

void shareMultipleQrWeb(List<Uint8List> qrImages, List<String> fileNames) {
  // Trên web, chúng ta sẽ tạo một zip file hoặc tải từng file một
  // Vì web không hỗ trợ tạo zip trực tiếp, ta sẽ tải từng file
  for (int i = 0; i < qrImages.length; i++) {
    final blob = html.Blob([qrImages[i]], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileNames[i])
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

void savePdfWeb(Uint8List pdfBytes, String fileName) {
  final blob = html.Blob([pdfBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
} 