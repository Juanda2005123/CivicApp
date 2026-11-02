import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/check.dart';

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('check_tool_'));
  tearDown(() => root.deleteSync(recursive: true));

  void write(String path, String content) {
    File('${root.path}/$path')
      ..createSync(recursive: true)
      ..writeAsStringSync(content);
  }

  test('a clean tree has no violations', () {
    write('lib/features/a/domain/x.dart', 'class X {}\n');
    write('lib/features/a/ui/bloc/b.dart', 'class B {}\n');
    expect(findViolations(root), isEmpty);
  });

  test('reports a Flutter import inside domain', () {
    write('lib/features/a/domain/x.dart', "import 'package:flutter/material.dart';\n");
    final violations = findViolations(root);
    expect(violations, hasLength(1));
    expect(violations.single, contains('lib/features/a/domain/x.dart:1'));
  });

  test('reports BuildContext in a bloc, a repository in a screen and print in lib', () {
    write('lib/features/a/ui/bloc/b.dart', 'void f(BuildContext c) {}\n');
    write('lib/features/a/ui/screens/s.dart', 'final r = FooRepository();\n');
    write('lib/core/p.dart', "void f() { print('x'); }\n");
    expect(findViolations(root), hasLength(3));
  });
}
