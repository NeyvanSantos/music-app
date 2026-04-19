void main() {
  String clean(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

  bool hasUpdate(String remoteStr, String localStr) {
    try {
      final remoteBase = clean(remoteStr.split('+')[0]);
      final localBase = clean(localStr.split('+')[0]);

      final remoteParts = remoteBase.split('.');
      final localParts = localBase.split('.');

      // Compara X.Y.Z
      for (int i = 0; i < 3; i++) {
        final r =
            i < remoteParts.length ? int.tryParse(remoteParts[i]) ?? 0 : 0;
        final l = i < localParts.length ? int.tryParse(localParts[i]) ?? 0 : 0;

        if (r > l) return true;
        if (r < l) return false;
      }

      // Se X.Y.Z forem iguais, comparamos o build number (+X)
      if (remoteStr.contains('+') && localStr.contains('+')) {
        final rBuild = int.tryParse(
                remoteStr.split('+')[1].replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
        final lBuild = int.tryParse(
                localStr.split('+')[1].replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;

        if (rBuild > lBuild) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  print("Rem: 2.3.2, Loc: 2.3.1+1 -> ${hasUpdate("2.3.2", "2.3.1+1")}");
  print("Rem: 2.3.2, Loc: 2.3.2+1 -> ${hasUpdate("2.3.2", "2.3.2+1")}");
  print("Rem: 2.3.2+2, Loc: 2.3.2+1 -> ${hasUpdate("2.3.2+2", "2.3.2+1")}");
}
