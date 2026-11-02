import 'dart:io';

/// One architecture guard from AGENTS.md section 11: [pattern] must not
/// appear in any `.dart` file under the folders that [dirs] resolves to.
class Guard {
  const Guard(this.name, this.pattern, this.dirs);

  final String name;
  final RegExp pattern;

  /// Paths relative to `lib/features/<feature>/`.
  final List<String> dirs;
}

final guards = <Guard>[
  Guard('domain is pure Dart',
      RegExp(r"import '.*/(data|ui)/|flutter|supabase|package:http"), ['domain']),
  Guard('ui does not import SDKs',
      RegExp(r'supabase_flutter|package:http|image_picker|geolocator'), ['ui']),
  Guard('screens talk to Blocs only',
      RegExp(r'UseCase|Repository|DataSource'), ['ui/screens', 'ui/pages']),
  Guard('blocs know nothing about widgets',
      RegExp(r'BuildContext|Navigator|SnackBar'), ['ui/bloc', 'ui/cubit']),
];

final _printCall = RegExp(r'\bprint\(');

/// Returns `path:line: text` for every guard violation under [root] (the repo root).
List<String> findViolations(Directory root) {
  final violations = <String>[];
  final features = Directory('${root.path}/lib/features');
  if (features.existsSync()) {
    for (final feature in features.listSync().whereType<Directory>()) {
      for (final guard in guards) {
        for (final dir in guard.dirs) {
          violations.addAll(_scan(Directory('${feature.path}/$dir'), guard.pattern, guard.name));
        }
      }
    }
  }
  violations.addAll(_scan(Directory('${root.path}/lib'), _printCall, 'no print() in lib'));
  return violations;
}

List<String> _scan(Directory dir, RegExp pattern, String rule) {
  if (!dir.existsSync()) return const [];
  final found = <String>[];
  for (final file in dir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (pattern.hasMatch(lines[i])) {
        found.add('[$rule] ${file.path.replaceAll('\\', '/')}:${i + 1}: ${lines[i].trim()}');
      }
    }
  }
  return found;
}

Future<int> _run(String executable, List<String> args) async {
  stdout.writeln('\n> $executable ${args.join(' ')}');
  // runInShell lets Windows resolve flutter.bat.
  final process = await Process.start(executable, args,
      mode: ProcessStartMode.inheritStdio, runInShell: true);
  return process.exitCode;
}

/// Cross-platform pre-completion check: `dart run tool/check.dart [--guards-only]`.
Future<void> main(List<String> args) async {
  final violations = findViolations(Directory.current);
  if (violations.isNotEmpty) {
    stdout.writeln('Architecture guards failed:');
    violations.forEach(stdout.writeln);
    exit(1);
  }
  stdout.writeln('Architecture guards: OK');
  if (args.contains('--guards-only')) return;

  for (final step in [
    ['analyze'],
    ['test'],
  ]) {
    final code = await _run('flutter', step);
    if (code != 0) exit(code);
  }
  stdout.writeln('\nAll checks passed.');
}
