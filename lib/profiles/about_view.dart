import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

class AboutView extends ConsumerWidget {
  const AboutView({super.key});

  static const contactEmail = 'tizalibre.contacto@gmail.com';
  static const licensesKey = ValueKey('licenses');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context).textTheme;
    final version = ref.watch(appVersionProvider).value ?? '';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Lee con Leo', style: theme.headlineSmall),
        Text('Versión $version', style: theme.bodyMedium),
        const SizedBox(height: 16),
        Text(
          'Una aplicación gratuita y de código abierto hecha por Tiza Libre. No tiene publicidad, '
          'no se conecta a internet y no recoge datos: el progreso se guarda solo en este '
          'dispositivo.',
          style: theme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text('Contacto', style: theme.titleLarge),
        const SizedBox(height: 8),
        SelectableText(contactEmail, style: theme.bodyLarge),
        const SizedBox(height: 24),
        Text('Créditos', style: theme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Dibujos y textos: Lee con Leo, licencia CC BY-SA 4.0.\n'
          'Voz de Leo: generada con VoxCPM2, licencia CC BY-SA 4.0.\n'
          'Letra ligada: Playwrite Chile, de TypeTogether, licencia SIL Open Font License 1.1.\n'
          'Código: licencia MIT.',
          style: theme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            key: licensesKey,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Lee con Leo',
              applicationVersion: version,
            ),
            child: const Text('Ver licencias'),
          ),
        ),
      ],
    );
  }
}
