# Contador de puntuaciones

Una app móvil desarrollada en Flutter para llevar la puntuación de juegos de mesa y cartas. Diseño moderno basado en Material 3 con una paleta de colores suaves, y disponible para Android, iOS, Web, Windows, macOS y Linux.

## Juegos disponibles

- **Contador general**: añade jugadores y suma o resetea sus puntos libremente. Pensado para cualquier juego de cartas que se puntúe por rondas.
- **Dardos**: añade los jugadores, sortea el orden de turno al azar y juega una partida de 301/501/701/901 con las reglas clásicas de cierre a doble. Incluye:
  - Lanzamiento dardo a dardo (valor 1-20, bull, y multiplicador simple/doble/triple).
  - Detección automática de turno anulado ("bust") y de victoria.
  - Historial de turnos y marcador final con estadísticas por jugador (turnos, dardos, puntos, media por dardo).
  - Partida guardada automáticamente: si cierras la app a mitad de partida, puedes continuarla al volver a abrirla.

## Primeros pasos

Requiere el [SDK de Flutter](https://docs.flutter.dev/get-started/install) (^3.5.0).

```bash
flutter pub get      # instalar dependencias
flutter run           # ejecutar en un dispositivo/emulador conectado
flutter analyze       # análisis estático
flutter test           # ejecutar tests
flutter build apk     # generar el APK de Android (o build ios / build web, etc.)
```

Más detalles de arquitectura y convenciones del proyecto en [CLAUDE.md](CLAUDE.md).
