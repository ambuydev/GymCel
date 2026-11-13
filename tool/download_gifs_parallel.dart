import 'dart:io';

void main() async {
  print('Iniciando descarga PARALELA de los 34 GIFs 3D VERIFICADOS...');

  final gifsDir = Directory('assets/gifs');
  if (!gifsDir.existsSync()) {
    gifsDir.createSync(recursive: true);
  }

  const baseUrl = 'https://raw.githubusercontent.com/lontraeye/exercise-gifs-db/main/';

  final Map<String, String> verifiedGifMap = {
    // Pecho (5)
    'bench_press.gif': 'pectorals/barbell-bench-press.gif',
    'incline_bench_press.gif': 'pectorals/barbell-incline-bench-press.gif',
    'chest_fly.gif': 'pectorals/cable-cross-over-variation.gif',
    'dips.gif': 'triceps/triceps-dip.gif',
    'pushups.gif': 'pectorals/push-up.gif',

    // Espalda (6)
    'pullups.gif': 'lats/pull-up.gif',
    'lat_pulldown.gif': 'lats/cable-pulldown.gif',
    'barbell_row.gif': 'upper-back/barbell-bent-over-row.gif',
    'dumbbell_row.gif': 'upper-back/dumbbell-one-arm-bent-over-row.gif',
    'deadlift.gif': 'glutes/barbell-deadlift.gif',
    'dead_hang.gif': 'lats/pull-up.gif',

    // Piernas (7)
    'squat.gif': 'glutes/barbell-full-squat.gif',
    'leg_press.gif': 'glutes/sled-45-leg-press.gif',
    'romanian_deadlift.gif': 'glutes/barbell-romanian-deadlift.gif',
    'leg_extension.gif': 'quads/lever-leg-extension.gif',
    'leg_curl.gif': 'hamstrings/lever-lying-leg-curl.gif',
    'calf_raise.gif': 'calves/lever-standing-calf-raise.gif',
    'wall_sit.gif': 'glutes/march-sit-wall.gif',

    // Hombros (4)
    'overhead_press.gif': 'delts/barbell-standing-overhead-press.gif',
    'dumbbell_shoulder_press.gif': 'delts/dumbbell-seated-shoulder-press.gif',
    'lateral_raises.gif': 'delts/dumbbell-lateral-raise.gif',
    'rear_delt_fly.gif': 'delts/dumbbell-rear-delt-fly.gif',

    // Brazos (4)
    'biceps_curl.gif': 'biceps/barbell-curl.gif',
    'hammer_curl.gif': 'biceps/dumbbell-hammer-curl.gif',
    'triceps_pushdown.gif': 'triceps/cable-pushdown.gif',
    'skull_crusher.gif': 'triceps/barbell-lying-triceps-extension.gif',

    // Core (4)
    'crunches.gif': 'abs/3-4-sit-up.gif',
    'plank.gif': 'abs/front-plank-with-twist.gif',
    'side_plank.gif': 'abs/bodyweight-incline-side-plank.gif',
    'hanging_leg_raise.gif': 'abs/hanging-leg-raise.gif',

    // Cardio (4)
    'treadmill.gif': 'cardio/walking-on-incline-treadmill.gif',
    'stationary_bike.gif': 'cardio/stationary-bike.gif',
    'running.gif': 'cardio/running.gif',
    'rowing_machine.gif': 'cardio/rowing-machine.gif',
  };

  final client = HttpClient();
  int completedCount = 0;

  final futures = verifiedGifMap.entries.map((entry) async {
    final localFilename = entry.key;
    final remotePath = entry.value;
    final targetFile = File('assets/gifs/$localFilename');
    final fullUrl = '$baseUrl$remotePath';

    try {
      final request = await client.getUrl(Uri.parse(fullUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
        await targetFile.writeAsBytes(bytes);
        completedCount++;
        print('✅ [$completedCount/34] $localFilename (${bytes.length} bytes)');
      } else {
        print('⚠️ HTTP ${response.statusCode} para $remotePath');
      }
    } catch (e) {
      print('❌ Error descargando $localFilename: $e');
    }
  });

  await Future.wait(futures);
  client.close();
  print('\n🎉 Proceso PARALELO completado. $completedCount/34 GIFs descargados exitosamente!');
}
