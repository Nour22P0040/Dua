import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Arabic dua text: always RTL, rendered with the Amiri naskh font.
///
/// google_fonts downloads Amiri once and caches it; until then (or offline on
/// first launch) the platform Arabic font is used. To ship the font offline,
/// see "Bundling the Arabic font" in the README.
class ArabicText extends StatelessWidget {
  const ArabicText(
    this.text, {
    super.key,
    this.fontSize = 24,
    this.maxLines,
    this.textAlign = TextAlign.center,
    this.color,
  });

  final String text;
  final double fontSize;
  final int? maxLines;
  final TextAlign textAlign;
  final Color? color;

  static TextStyle style(BuildContext context, {double fontSize = 24, Color? color}) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      height: 1.9,
      color: color ?? Theme.of(context).colorScheme.onSurface,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      style: style(context, fontSize: fontSize, color: color),
    );
  }
}
