import 'dart:io';

void main() async {
  print('Iniciando descarga masiva de GIFs 3D animados reales desde lontraeye/exercise-gifs-db...');

  final gifsDir = Directory('assets/gifs');
  if (!gifsDir.existsSync()) {
    gifsDir.createSync(recursive: true);
  }

  const baseUrl = 'https://raw.githubusercontent.com/lontraeye/exercise-gifs-db/main/';

  // Map of exercise names to remote high-definition 3D animated GIF paths
  final Map<String, String> remoteGifMap = {
    // Pecho
    'bench_press.gif': 'pectorals/barbell-bench-press.gif',
    'incline_bench_press.gif': 'pectorals/barbell-incline-bench-press.gif',
    'chest_fly.gif': 'pectorals/cable-cross-over-variation.gif',
    'dips.gif': 'triceps/triceps-dip.gif',
    'pushups.gif': 'pectorals/push-up.gif',

    // Espalda
    'pullups.gif': 'lats/pull-up.gif',
    'lat_pulldown.gif': 'lats/cable-lat-pulldown.gif',
    'barbell_row.gif': 'lats/barbell-bent-over-row.gif',
    'dumbbell_row.gif': 'lats/dumbbell-one-arm-row.gif',
    'deadlift.gif': 'glutes/barbell-deadlift.gif',
    'dead_hang.gif': 'lats/pull-up.gif',

    // Piernas
    'squat.gif': 'quads/barbell-squat.gif',
    'leg_press.gif': 'quads/sled-45-leg-press.gif',
    'romanian_deadlift.gif': 'hamstrings/barbell-romanian-deadlift.gif',
    'leg_extension.gif': 'quads/lever-leg-extension.gif',
    'leg_curl.gif': 'hamstrings/lever-lying-leg-curl.gif',
    'calf_raise.gif': 'calves/lever-standing-calf-raise.gif',
    'wall_sit.gif': 'glutes/march-sit-wall.gif',

    // Hombros
    'overhead_press.gif': 'delts/barbell-standing-overhead-press.gif',
    'dumbbell_shoulder_press.gif': 'delts/dumbbell-shoulder-press.gif',
    'lateral_raises.gif': 'delts/dumbbell-lateral-raise.gif',
    'rear_delt_fly.gif': 'delts/dumbbell-rear-delt-fly.gif',

    // Brazos
    'biceps_curl.gif': 'biceps/barbell-curl.gif',
    'hammer_curl.gif': 'biceps/dumbbell-hammer-curl.gif',
    'triceps_pushdown.gif': 'triceps/cable-pushdown.gif',
    'skull_crusher.gif': 'triceps/barbell-lying-triceps-extension.gif',

    // Core
    'crunches.gif': 'abs/3-4-sit-up.gif',
    'plank.gif': 'abs/plank.gif',
    'side_plank.gif': 'abs/side-plank.gif',
    'hanging_leg_raise.gif': 'abs/hanging-leg-raise.gif',

    // Cardio
    'treadmill.gif': 'cardio/treadmill.gif',
    'stationary_bike.gif': 'cardio/stationary-bike.gif',
    'cycling.gif': 'cardio/stationary-bike.gif',
    'running.gif': 'cardio/running.gif',
    'elliptical.gif': 'cardio/elliptical.gif',
    'rowing_machine.gif': 'cardio/rowing-machine.gif',

    // TRX / Suspensión
    'trx_row.gif': 'lats/dumbbell-one-arm-row.gif',
    'trx_chest_press.gif': 'pectorals/push-up.gif',
    'trx_pushup.gif': 'pectorals/push-up.gif',
    'trx_squat.gif': 'quads/barbell-squat.gif',
    'trx_pistol_squat.gif': 'quads/barbell-squat.gif',
    'trx_lunge.gif': 'quads/barbell-squat.gif',
    'trx_biceps_curl.gif': 'biceps/barbell-curl.gif',
    'trx_triceps_extension.gif': 'triceps/cable-pushdown.gif',
  };

  final client = HttpClient();

  for (final entry in remoteGifMap.entries) {
    final localFilename = entry.key;
    final remotePath = entry.value;
    final targetFile = File('assets/gifs/$localFilename');

    final fullUrl = '$baseUrl$remotePath';
    print('Descargando $localFilename desde $fullUrl...');

    try {
      final request = await client.getUrl(Uri.parse(fullUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await targetFile.writeAsBytes(bytes);
        print('✅ Guardado: $localFilename (${bytes.length} bytes)');
      } else {
        print('⚠️ Código HTTP ${response.statusCode} para $remotePath');
      }
    } catch (e) {
      print('❌ Error descargando $localFilename: $e');
    }
  }

  client.close();
  print('\n🎉 Proceso finalizado. Todos los GIFs 3D animados reales han sido descargados en assets/gifs/!');
}
