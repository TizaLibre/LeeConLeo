abstract final class SpanishLetters {
  static const strongVowels = {'a', 'e', 'o', 'á', 'é', 'ó', 'í', 'ú'};
  static const weakVowels = {'i', 'u', 'ü'};
  static const frontVowels = {'e', 'i', 'é', 'í'};
  static const _accentless = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};

  static bool isVowel(String letter) =>
      strongVowels.contains(letter) || weakVowels.contains(letter);

  static bool isStrongVowel(String letter) => strongVowels.contains(letter);

  static bool isFrontVowel(String letter) => frontVowels.contains(letter);

  static String withoutAccent(String letter) => _accentless[letter] ?? letter;

  static String plain(String text) => text.toLowerCase().split('').map(withoutAccent).join();
}
