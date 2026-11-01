import 'package:flutter_test/flutter_test.dart';
import 'package:lee_con_leo/core/content/clap_words.dart';
import 'package:lee_con_leo/core/content/models/word.dart';

Word _word(String text, List<String> syllables) => Word(
  text: text,
  syllables: syllables,
  sounds: syllables,
  image: 'words/$text.svg',
  audio: 'words/$text.m4a',
);

void main() {
  test('words whose split would turn a soft r into a strong rr are not clapped', () {
    final words = [
      _word('pera', ['pe', 'ra']),
      _word('caramelo', ['ca', 'ra', 'me', 'lo']),
      _word('perro', ['pe', 'rro']),
      _word('ratón', ['ra', 'tón']),
      _word('mesa', ['me', 'sa']),
    ];

    expect(ClapWords.all(words).map((word) => word.text), ['perro', 'ratón', 'mesa']);
  });
}
