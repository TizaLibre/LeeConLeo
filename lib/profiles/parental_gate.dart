import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../app/app_theme.dart';

class ParentalGate extends StatefulWidget {
  const ParentalGate({super.key, required this.onPassed, this.random});

  static const numberWords = {5: 'cinco', 6: 'seis', 7: 'siete', 8: 'ocho', 9: 'nueve'};
  static const questionKey = ValueKey('gate-question');

  final VoidCallback onPassed;
  final Random? random;

  @override
  State<ParentalGate> createState() => _ParentalGateState();
}

class _ParentalGateState extends State<ParentalGate> {
  late final Random _random = widget.random ?? Random();
  late (int, int) _addends = _ask();
  String _typed = '';

  (int, int) _ask() {
    final numbers = ParentalGate.numberWords.keys.toList();
    return (numbers[_random.nextInt(numbers.length)], numbers[_random.nextInt(numbers.length)]);
  }

  void _type(String digit) {
    final typed = _typed + digit;
    final answer = '${_addends.$1 + _addends.$2}';
    if (typed.length < answer.length) return setState(() => _typed = typed);
    if (typed == answer) return widget.onPassed();
    setState(() {
      _typed = '';
      _addends = _ask();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _question(),
                ),
                const SizedBox.square(dimension: 24),
                SizedBox(width: 300, child: _keypad()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _question() {
    final (a, b) = _addends;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Solo para adultos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.outline),
        ),
        const SizedBox(height: 12),
        Text(
          '¿Cuánto es ${ParentalGate.numberWords[a]} más ${ParentalGate.numberWords[b]}?',
          key: ParentalGate.questionKey,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: AppTheme.outline),
        ),
        const SizedBox(height: 16),
        Text(
          _typed.padRight(2, '_').split('').join(' '),
          style: const TextStyle(fontSize: 32, letterSpacing: 4, color: AppTheme.outline),
        ),
      ],
    );
  }

  Widget _keypad() => GridView.count(
    crossAxisCount: 3,
    childAspectRatio: 1.6,
    shrinkWrap: true,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    physics: const NeverScrollableScrollPhysics(),
    children: [
      for (final digit in '1234567890'.split(''))
        FilledButton.tonal(
          key: ValueKey('digit-$digit'),
          onPressed: () => _type(digit),
          child: Text(digit, style: const TextStyle(fontSize: 28)),
        ),
    ],
  );
}
