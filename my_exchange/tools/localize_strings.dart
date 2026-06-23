import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where(
    (f) => f.path.endsWith('.dart') && !f.path.contains('.g.dart'),
  );

  final allStrings = <String, List<String>>{};
  final cyrillicPattern = RegExp(r"'([^']*[А-Яа-я][^']*)'");
  final cyrillicPattern2 = RegExp(r'"([^"]*[А-Яа-я][^"]*)"');

  for (final file in files) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    final fileStrings = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      
      // Skip comments, imports, and already localized strings
      if (trimmed.startsWith('//') || trimmed.startsWith('///') || 
          trimmed.startsWith('import') || trimmed.startsWith('.t(') ||
          trimmed.contains('local.t(') || trimmed.contains('loc.t(') ||
          trimmed.contains("'t('") || trimmed.contains("AppStrings.") ||
          trimmed.contains('.displayName') ||
          trimmed.contains("'general_") || trimmed.contains("'settings_") ||
          trimmed.contains("'operations_") || trimmed.contains("'cash_") ||
          trimmed.contains("'currencies_") || trimmed.contains("'analytics_") ||
          trimmed.contains("'reports_") || trimmed.contains("'login_") ||
          trimmed.contains("'nav_") || trimmed.contains("'lock_") ||
          trimmed.contains("'app_")) {
        continue;
      }

      for (final match in cyrillicPattern.allMatches(line)) {
        String str = match.group(1)!;
        if (str.length > 2 && !str.startsWith('\\') && !str.startsWith('http')) {
          fileStrings.add('  ${file.path}:$i: $str');
        }
      }
      for (final match in cyrillicPattern2.allMatches(line)) {
        String str = match.group(1)!;
        if (str.length > 2 && !str.startsWith('\\') && !str.startsWith('http')) {
          fileStrings.add('  ${file.path}:$i: $str');
        }
      }
    }

    if (fileStrings.isNotEmpty) {
      allStrings[file.path] = fileStrings;
    }
  }

  // Print results
  final sorted = allStrings.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  
  int total = 0;
  for (final entry in sorted) {
    print('\n${entry.key}:');
    for (final s in entry.value) {
      print(s);
      total++;
    }
  }
  print('\n\nTotal hardcoded strings found: $total');
}
