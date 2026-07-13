/// Comparaison de versions sémantiques simplifiée (major.minor.patch).
/// Ignore le build number après un "+" (ex: "1.0.0+6" → "1.0.0").
class SemVer {
  SemVer._();

  /// -1 si [a] < [b], 0 si égal, 1 si [a] > [b].
  static int compare(String a, String b) {
    final pa = _parse(a);
    final pb = _parse(b);
    for (var i = 0; i < 3; i++) {
      final cmp = pa[i].compareTo(pb[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  static bool isLowerThan(String a, String b) => compare(a, b) < 0;

  static List<int> _parse(String version) {
    final core = version.trim().split('+').first;
    final parts = core.split('.');
    return List.generate(
      3,
      (i) => i < parts.length ? (int.tryParse(parts[i].trim()) ?? 0) : 0,
    );
  }
}
