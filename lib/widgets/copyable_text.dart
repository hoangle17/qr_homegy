import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? copyMessage;
  final VoidCallback? onCopy;

  const CopyableText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.copyMessage,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
} 