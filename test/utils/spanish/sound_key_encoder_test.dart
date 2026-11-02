import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/utils/spanish/sound_key_encoder.dart';

void main() {
  const encoder = SoundKeyEncoder();

  const cases = {
    'cie-lo': 'sie-lo',
    'gen-te': 'jen-te',
    'he-la-do': 'e-la-do',
    'hie-lo': 'ye-lo',
    'hier-ba': 'yer-ba',
    'hi-lo': 'i-lo',
    'va-ca': 'ba-ka',
    'lla-ve': 'ya-be',
    'que-so': 'ke-so',
    'gui-ta-rra': 'gi-ta-rra',
    'ra-tón': 'rra-ton',
    'hon-ra': 'on-rra',
    'pe-ra': 'pe-ra',
    'pin-güi-no': 'pin-gui-no',
    'ya-te': 'ya-te',
    'rey': 'rrei',
    'za-pa-to': 'sa-pa-to',
    'ta-xi': 'ta-ksi',
  };

  cases.forEach((syllables, expected) {
    test('$syllables → $expected', () {
      expect(encoder.encodeAll(syllables.split('-')).join('-'), expected);
    });
  });
}
