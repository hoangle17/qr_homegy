import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void  saveQrWeb(Uint8List bytes) {
  final blob = html.Blob([bytes], 'image/jpeg');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', 'qr_code.jpg')
    ..click();
  html.Url.revokeObjectUrl(url);
} 