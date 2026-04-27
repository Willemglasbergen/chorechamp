class Format {
  // Formats integers with dot as thousands separator: 2000 -> 2.000
  static String points(int value) {
    final s = value.abs().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write('.');
    }
    final formatted = buf.toString();
    return value < 0 ? '-$formatted' : formatted;
  }
}
