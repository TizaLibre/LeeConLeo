import 'package:flutter/material.dart';

class AdultsGuide extends StatelessWidget {
  const AdultsGuide({super.key});

  static const sections = [
    (
      'Cómo funciona',
      'Lee con Leo parte con juegos de orientación en el espacio: arriba y abajo, izquierda y '
          'derecha, encima, debajo y entre. Después sigue el orden del Silabario: las vocales y '
          'luego las consonantes m, p, l, s, t, d, n, ñ y f, cada una con sus sílabas (ma, me, '
          'mi, mo, mu). Leo explica todo hablando, así que no hace falta saber leer para jugar.',
    ),
    (
      'El mapa',
      'Cada piedra del camino es un paso, y cada paso tiene varios juegos: escuchar, conocer la '
          'letra, repasarla con el dedo, encontrarla y formar palabras. Cuando juega todos los '
          'juegos de un paso una vez, se abre el siguiente. La estrella marca un paso terminado y '
          'la medalla, uno dominado.',
    ),
    (
      'El lápiz',
      'Desde la sílaba pa, el lápiz del mapa abre un juego para escribir palabras con el dedo '
          'sobre una guía en letra ligada. Leo pone de una a tres estrellas según qué tan bien '
          'quedó. Solo usa sílabas ya aprendidas, y es el juego para seguir practicando al '
          'terminar el camino.',
    ),
    (
      'Repaso',
      'Al empezar a jugar, Leo a veces pide repasar pasos ya dominados, sobre todo los que '
          'costaron más. Así lo aprendido no se olvida.',
    ),
    (
      'Perfiles',
      'La aplicación parte con un perfil llamado «Mi perfil», para poder jugar de inmediato. '
          'Puede cambiarle el apodo y el dibujo en la pestaña Perfiles. Si juegan dos o más '
          'niños, cree un perfil para cada uno: así cada uno avanza a su ritmo, y al abrir la '
          'aplicación cada uno toca su dibujo.',
    ),
    (
      'Recomendaciones',
      '• Juegue poco y seguido: 10 a 15 minutos al día rinden más que una sesión larga.\n'
          '• La primera vez, acompañe a su hija o hijo, con el sonido encendido.\n'
          '• Equivocarse es parte de aprender: Leo vuelve a explicar y da pistas.\n'
          '• Si se cansa o se frustra, mejor parar y seguir otro día.',
    ),
    (
      'Fuera de la pantalla',
      '• Busquen juntos cosas que empiecen con la sílaba del día: «ma» de mano, mesa, mamá.\n'
          '• Aplaudan las sílabas de los nombres de la familia.\n'
          '• Dibujen la letra en el aire, en arena o con el dedo en la espalda.\n'
          '• La app usa letra ligada, la cursiva que se enseña en los colegios de Chile.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        for (final (title, body) in sections) ...[
          Text(title, style: theme.titleLarge),
          const SizedBox(height: 8),
          Text(body, style: theme.bodyLarge),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
