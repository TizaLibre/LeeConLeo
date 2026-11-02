import 'dart:io';

import 'src/commands/beats_command.dart';
import 'src/commands/build_command.dart';
import 'src/commands/content_command.dart';
import 'src/commands/import_legacy_command.dart';
import 'src/commands/validate_command.dart';
import 'src/commands/voice_command.dart';

const _commands = <ContentCommand>[
  ValidateCommand(),
  BuildCommand(),
  VoiceCommand(),
  BeatsCommand(),
  ImportLegacyCommand(),
];

void main(List<String> arguments) {
  final command = _commands
      .where((c) => arguments.isNotEmpty && c.name == arguments.first)
      .firstOrNull;
  if (command == null) {
    print('Usage: dart run tool/content.dart <command>\n');
    for (final c in _commands) {
      print('  ${c.usage}');
    }
    exit(64);
  }
  exit(command.run(arguments.skip(1).toList()));
}
