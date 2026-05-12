import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:seil_mobile/app.dart';

void main() {
  test('creates the mobile app widget', () {
    expect(const SeilMobileApp(), isA<SeilMobileApp>());
  });

  test('keeps Korean app strings in localization', () {
    final korean = RegExp(r'[가-힣]');
    final offenders = <String>[];

    for (final file
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.endsWith('seil_localizations.dart')) {
        continue;
      }
      if (korean.hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Move Korean app strings to SeilLocalizations.',
    );
  });
}
