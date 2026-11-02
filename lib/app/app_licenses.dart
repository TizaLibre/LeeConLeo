import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class AppLicenses {
  static const contentNotice =
      'The pictures, prompts, word lists, learning path, stroke data and Leo\'s voice of '
      'Lee con Leo are licensed under Creative Commons Attribution-ShareAlike 4.0 '
      'International (CC BY-SA 4.0): https://creativecommons.org/licenses/by-sa/4.0/\n\n'
      'Leo\'s voice was generated with VoxCPM2 (openbmb/VoxCPM2, Apache-2.0).';

  static void register(AssetBundle bundle) {
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['Lee con Leo'], await bundle.loadString('LICENSE'));
      yield const LicenseEntryWithLineBreaks(['Lee con Leo (content)'], contentNotice);
      yield LicenseEntryWithLineBreaks([
        'Playwrite Chile',
      ], await bundle.loadString('assets/fonts/OFL.txt'));
    });
  }
}
