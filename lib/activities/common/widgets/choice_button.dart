import 'package:material_ui/material_ui.dart';

class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.isHighlighted = false,
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: isHighlighted ? colors.tertiary : Colors.transparent, width: 8),
        ),
        child: Material(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: FittedBox(
                  child: IconTheme.merge(
                    data: IconThemeData(size: 160, color: colors.onPrimaryContainer),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: colors.onPrimaryContainer),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
