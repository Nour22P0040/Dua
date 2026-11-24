/// Normalizes text for forgiving search (mostly Arabic):
/// removes diacritics (tashkeel) and tatweel, unifies alef/yaa/taa-marbuta
/// variants, and lower-cases Latin text. "الجنّة" matches "الجنه".
String normalizeForSearch(String input) {
  final buffer = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    // Tashkeel U+064B–U+065F, superscript alef U+0670, tatweel U+0640.
    if ((rune >= 0x064B && rune <= 0x065F) || rune == 0x0670 || rune == 0x0640) {
      continue;
    }
    switch (rune) {
      case 0x0622: // آ
      case 0x0623: // أ
      case 0x0625: // إ
      case 0x0671: // ٱ
        buffer.writeCharCode(0x0627); // ا
      case 0x0649: // ى
        buffer.writeCharCode(0x064A); // ي
      case 0x0629: // ة
        buffer.writeCharCode(0x0647); // ه
      case 0x0624: // ؤ
        buffer.writeCharCode(0x0648); // و
      case 0x0626: // ئ
        buffer.writeCharCode(0x064A); // ي
      default:
        buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}
