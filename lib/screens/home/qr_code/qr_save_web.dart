import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:archive/archive.dart';

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
  // Trên web: chọn 1 -> tải ảnh, chọn nhiều -> gom file ZIP
  if (qrImages.length == 1) {
    // Chỉ 1 ảnh: tải trực tiếp
    final blob = html.Blob([qrImages[0]], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileNames[0])
      ..style.display = 'none';
    
    html.document.body?.append(anchor);
    anchor.click();
    
    // Cleanup
    Future.delayed(const Duration(milliseconds: 100), () {
      html.Url.revokeObjectUrl(url);
      anchor.remove();
    });
  } else {
    // Nhiều ảnh: gom vào file ZIP
    final archive = Archive();
    
    // Thêm từng QR code vào archive
    for (int i = 0; i < qrImages.length; i++) {
      final archiveFile = ArchiveFile(
        fileNames[i], // Tên file trong ZIP
        qrImages[i].length, // Kích thước file
        qrImages[i], // Dữ liệu file
      );
      archive.addFile(archiveFile);
    }
    
    // Tạo file ZIP
    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      // Tạo blob từ ZIP data
      final blob = html.Blob([zipData], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Tạo anchor element để download
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'qr_codes.zip')
        ..style.display = 'none';
      
      // Thêm vào DOM và trigger download
      html.document.body?.append(anchor);
      anchor.click();
      
      // Cleanup
      Future.delayed(const Duration(milliseconds: 100), () {
        html.Url.revokeObjectUrl(url);
        anchor.remove();
      });
    }
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