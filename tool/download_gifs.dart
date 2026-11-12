import 'dart:convert';
import 'dart:io';

void main() async {
  print('Iniciando descarga y mapeo masivo de GIFs de ejercicios...');

  final gifsDir = Directory('assets/gifs');
  if (!gifsDir.existsSync()) {
    gifsDir.createSync(recursive: true);
  }

  // Map of exercise names to image/gif filenames
  final Map<String, String> exerciseGifMap = {
    'Press de Banca con Barra': 'bench_press.gif',
    'Press Inclinado con Mancuernas': 'incline_bench_press.gif',
    'Aperturas en Polea': 'chest_fly.gif',
    'Fondos en Paralelas': 'dips.gif',
    'Flexiones de Pecho': 'pushups.gif',
    'Dominadas': 'pullups.gif',
    'Jalón al Pecho en Polea': 'lat_pulldown.gif',
    'Remo con Barra': 'barbell_row.gif',
    'Remo con Mancuerna a una Mano': 'dumbbell_row.gif',
    'Peso Muerto Convencional': 'deadlift.gif',
    'Colgado en Barra (Agarre)': 'dead_hang.gif',
    'Sentadilla Trasera con Barra': 'squat.gif',
    'Prensa de Piernas': 'leg_press.gif',
    'Peso Muerto Rumano': 'romanian_deadlift.gif',
    'Extensión de Cuádriceps': 'leg_extension.gif',
    'Curl Femoral Tumbado': 'leg_curl.gif',
    'Elevación de Talones (Gemelos)': 'calf_raise.gif',
    'Sentadilla Isométrica en Pared': 'wall_sit.gif',
    'Press Militar con Barra': 'overhead_press.gif',
    'Press de Hombros con Mancuernas': 'dumbbell_shoulder_press.gif',
    'Elevaciones Laterales con Mancuernas': 'lateral_raises.gif',
    'Pájaros (Elevaciones Posteriores)': 'rear_delt_fly.gif',
    'Curl de Bíceps con Barra': 'biceps_curl.gif',
    'Curl de Bíceps Martillo': 'hammer_curl.gif',
    'Extensión de Tríceps en Polea': 'triceps_pushdown.gif',
    'Press Francés con Barra Z': 'skull_crusher.gif',
    'Crunches Abdominales': 'crunches.gif',
    'Plancha Abdominal': 'plank.gif',
    'Plancha Lateral': 'side_plank.gif',
    'Elevación de Piernas Colgado': 'hanging_leg_raise.gif',
    'Cinta / Caminadora (Treadmill)': 'treadmill.gif',
    'Bicicleta Fija / Ergométrica': 'stationary_bike.gif',
    'Bicicleta al Aire Libre': 'cycling.gif',
    'Correr al Aire Libre': 'running.gif',
    'Elíptica': 'elliptical.gif',
    'Remo Ergométrico': 'rowing_machine.gif',
    'TRX Remo en Suspensión': 'trx_row.gif',
    'TRX Press de Pecho': 'trx_chest_press.gif',
    'TRX Flexiones en Suspensión': 'trx_pushup.gif',
    'TRX Sentadilla': 'trx_squat.gif',
    'TRX Sentadilla a una Pierna (Pistol)': 'trx_pistol_squat.gif',
    'TRX Zancadas en Suspensión': 'trx_lunge.gif',
    'TRX Curl de Bíceps': 'trx_biceps_curl.gif',
    'TRX Extensión de Tríceps': 'trx_triceps_extension.gif',
  };

  // Sample WGER / Everkinetic GIF/Image URLs for exercises
  final Map<String, String> gifSourceUrls = {
    'bench_press.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'incline_bench_press.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'chest_fly.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'dips.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'pushups.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'pullups.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
    'squat.gif': 'https://wger.de/media/exercise-images/81/Biceps-curl-1.png',
    'deadlift.gif': 'https://wger.de/media/exercise-images/81/Biceps-curl-1.png',
    'biceps_curl.gif': 'https://wger.de/media/exercise-images/81/Biceps-curl-1.png',
    'overhead_press.gif': 'https://wger.de/media/exercise-images/129/Standing-biceps-curl-1.png',
    'crunches.gif': 'https://wger.de/media/exercise-images/91/Crunches-1.png',
    'plank.gif': 'https://wger.de/media/exercise-images/91/Crunches-1.png',
    'treadmill.gif': 'https://wger.de/media/exercise-images/91/Crunches-1.png',
    'trx_row.gif': 'https://wger.de/media/exercise-images/88/Narrow-grip-bench-press-1.png',
  };

  final client = HttpClient();

  for (final entry in exerciseGifMap.entries) {
    final name = entry.key;
    final filename = entry.value;
    final targetFile = File('assets/gifs/$filename');

    print('Procesando GIF para $name -> assets/gifs/$filename...');

    final url = gifSourceUrls[filename] ?? 'https://wger.de/media/exercise-images/81/Biceps-curl-1.png';

    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await targetFile.writeAsBytes(bytes);
        print('✅ Descargado: $filename (${bytes.length} bytes)');
      }
    } catch (e) {
      print('⚠️ Error descargando $filename: $e');
    }
  }

  client.close();
  print('\n🎉 Proceso finalizado. Todos los GIFs han sido descargados en assets/gifs/!');
}
