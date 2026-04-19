/// Teste unitário isolado para diagnosticar o loop OTA.
/// Simula TODOS os cenários reais de comparação de versão.
library;

// Cópia exata da lógica de hasUpdate para teste isolado (sem dependência Flutter)
bool hasUpdate(String remoteStr, String localStr) {
  try {
    String clean(String s) => s.replaceAll(RegExp(r'[^0-9.]'), '');

    final remoteBase = clean(remoteStr.split('+')[0]);
    final localBase = clean(localStr.split('+')[0]);

    final remoteParts = remoteBase.split('.');
    final localParts = localBase.split('.');

    // Compara X.Y.Z
    for (int i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? int.tryParse(remoteParts[i]) ?? 0 : 0;
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

/// Simula getCurrentVersion() → retorna "X.Y.Z+buildNumber"
String simulateGetCurrentVersion(String pubspecVersion) {
  // pubspec: "2.3.2+4" → version="2.3.2", buildNumber="4"
  // getCurrentVersion retorna "${version}+${buildNumber}" = "2.3.2+4"
  return pubspecVersion; // já está no formato correto
}

void main() {
  int pass = 0;
  int fail = 0;

  void test(String name, bool actual, bool expected) {
    if (actual == expected) {
      print('  ✅ PASS: $name → $actual');
      pass++;
    } else {
      print('  ❌ FAIL: $name → got $actual, expected $expected');
      fail++;
    }
  }

  print('');
  print('====================================================');
  print('  TESTE UNITÁRIO: UpdateService.hasUpdate()');
  print('====================================================');
  print('');

  // ─────────────────────────────────────────────
  // CENÁRIO 1: Firebase com "2.3.2" (sem build number)
  //            App instalado com versão antiga "2.3.1+1"
  // Esperado: TRUE (precisa atualizar)
  // ─────────────────────────────────────────────
  print('▸ Cenário 1: App antigo, Firebase com versão nova (sem +)');
  test(
    'Remote="2.3.2" vs Local="2.3.1+1"',
    hasUpdate('2.3.2', '2.3.1+1'),
    true,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 2: Firebase com "2.3.2" (sem build number)
  //            App ATUALIZADO com "2.3.2+4"
  // Esperado: FALSE (já está atualizado, NÃO mostrar overlay!)
  // *** ESTE É O CENÁRIO DO LOOP ***
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 2: ★★★ CENÁRIO DO LOOP ★★★');
  print('  Firebase: "2.3.2" | App instalado: "2.3.2+4"');
  test(
    'Remote="2.3.2" vs Local="2.3.2+4"',
    hasUpdate('2.3.2', '2.3.2+4'),
    false,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 3: Firebase com "2.3.2" (sem build number)
  //            App com "2.3.2+1" (build antigo, mesma versão)
  // Esperado: FALSE
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 3: Mesma versão base, build antigo');
  test(
    'Remote="2.3.2" vs Local="2.3.2+1"',
    hasUpdate('2.3.2', '2.3.2+1'),
    false,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 4: Firebase COM build number
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 4: Firebase com build number');
  test(
    'Remote="2.3.2+5" vs Local="2.3.2+4"',
    hasUpdate('2.3.2+5', '2.3.2+4'),
    true,
  );
  test(
    'Remote="2.3.2+4" vs Local="2.3.2+4"',
    hasUpdate('2.3.2+4', '2.3.2+4'),
    false,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 5: Versão futura no Firebase
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 5: Versão futura');
  test(
    'Remote="3.0.0" vs Local="2.3.2+4"',
    hasUpdate('3.0.0', '2.3.2+4'),
    true,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 6: getCurrentVersion() retorna o formato correto
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 6: Validação do formato de getCurrentVersion()');
  final simulated = simulateGetCurrentVersion('2.3.2+4');
  test(
    'getCurrentVersion("2.3.2+4") retorna "$simulated"',
    simulated == '2.3.2+4',
    true,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 7: Versão local MAIOR que o Firebase (downgrade)
  // ─────────────────────────────────────────────
  print('');
  print('▸ Cenário 7: Local maior que remote (sem loop)');
  test(
    'Remote="2.3.1" vs Local="2.3.2+4"',
    hasUpdate('2.3.1', '2.3.2+4'),
    false,
  );

  // ─────────────────────────────────────────────
  // CENÁRIO 8: Versão LIMPA do local (pré-build) com + no build
  // ─────────────────────────────────────────────
  print('');
  print(
      '▸ Cenário 8: Clean function remove caracteres não numéricos corretamente');
  test(
    'Remote="v2.3.2" vs Local="2.3.2+4" (com prefixo v)',
    hasUpdate('v2.3.2', '2.3.2+4'),
    false,
  );

  // ─────────────────────────────────────────────
  print('');
  print('====================================================');
  print('  RESULTADOS: $pass passed, $fail failed');
  print('====================================================');
  print('');

  if (fail > 0) {
    print(
        '⚠️  BUGS ENCONTRADOS! O loop é causado por cenários que falharam acima.');
  } else {
    print('✅ A lógica de comparação está CORRETA.');
    print('');
    print('Se o loop persiste, o problema NÃO é na comparação de versão.');
    print('Possíveis causas:');
    print(
        '  1. O APK baixado NÃO está sendo instalado com sucesso pelo Android');
    print(
        '  2. O Android está rejeitando silenciosamente (versionCode muito baixo)');
    print('  3. O app está reiniciando antes de completar a instalação');
  }
}
