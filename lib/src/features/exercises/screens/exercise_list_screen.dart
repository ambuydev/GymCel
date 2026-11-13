import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../providers/exercise_provider.dart';

class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key});

  final categories = const [
    'Todos',
    'Pecho',
    'Espalda',
    'Piernas',
    'Hombros',
    'Brazos',
    'Core',
    'Cardio',
    'TRX',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExerciseListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28, color: Color(0xFF00E676)),
            tooltip: 'Nuevo Ejercicio',
            onPressed: () => _showAddExerciseDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Muscle Group Category Selector Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) {
                      ref.read(selectedCategoryProvider.notifier).state = category;
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Exercise List
          Expanded(
            child: exercises.isEmpty
                ? const Center(
                    child: Text(
                      'No hay ejercicios en esta categoría',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      final gifAsset = _getGifAssetPath(exercise.name, exercise.category);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            exercise.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${exercise.category} • ${exercise.equipment ?? "General"}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                gifAsset != null ? Icons.slow_motion_video : Icons.info_outline,
                                color: const Color(0xFF00E676),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                exercise.isCustom ? Icons.person_outline : Icons.fitness_center,
                                color: exercise.isCustom ? const Color(0xFF00E676) : Colors.grey,
                                size: 20,
                              ),
                            ],
                          ),
                          onTap: () => _showExerciseDetailSheet(context, exercise),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetailSheet(BuildContext context, Exercise exercise) {
    final gifAsset = _getGifAssetPath(exercise.name, exercise.category);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      exercise.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Text(
                '${exercise.category} • ${exercise.equipment ?? "General"} • ${exercise.isCardio ? "Cardio" : (exercise.isTimeBased ? "Por Tiempo" : "Por Repeticiones")}',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Execution Preview Container (Local Verified 3D GIF)
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: gifAsset != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          gifAsset,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => _buildFallbackIllustration(exercise),
                        ),
                      )
                    : _buildFallbackIllustration(exercise),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conectando con Firebase Storage para cargar animación HD de TRX...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.hd),
                  label: const Text('Ver Detalle HD en la Nube', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackIllustration(Exercise exercise) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            exercise.isCardio
                ? Icons.directions_run
                : (exercise.category == 'TRX' ? Icons.sports_gymnastics : Icons.fitness_center),
            size: 48,
            color: const Color(0xFF00E676),
          ),
          const SizedBox(height: 8),
          Text(
            'Ejecución Técnica de ${exercise.name}',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          if (exercise.category == 'TRX') ...[
            const SizedBox(height: 4),
            const Text(
              'Sujeción en Cintas de Suspensión TRX',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String? _getGifAssetPath(String name, String category) {
    final lower = name.toLowerCase();

    // TRX / Suspensión
    if (category == 'TRX' || lower.contains('trx')) {
      if (lower.contains('remo')) return 'assets/gifs/trx_row.gif';
      if (lower.contains('press') || lower.contains('flexion')) return 'assets/gifs/trx_chest_press.gif';
      if (lower.contains('sentadilla') || lower.contains('pistol') || lower.contains('zancada')) return 'assets/gifs/trx_squat.gif';
      if (lower.contains('bíceps')) return 'assets/gifs/trx_biceps_curl.gif';
      if (lower.contains('tríceps')) return 'assets/gifs/trx_triceps_extension.gif';
      return 'assets/gifs/trx_row.gif';
    }

    // Cardio
    if (lower.contains('cinta') || lower.contains('caminadora')) return 'assets/gifs/treadmill.gif';
    if (lower.contains('bicicleta') || lower.contains('fija') || lower.contains('ergométrica')) return 'assets/gifs/stationary_bike.gif';
    if (lower.contains('elíptica')) return 'assets/gifs/elliptical.gif';
    if (lower.contains('remo ergométrico') || lower.contains('máquina de remo')) return 'assets/gifs/rowing_machine.gif';
    if (lower.contains('correr')) return 'assets/gifs/running.gif';

    // Traditional Gym Exercises
    if (lower.contains('press de banca')) return 'assets/gifs/bench_press.gif';
    if (lower.contains('inclinado')) return 'assets/gifs/incline_bench_press.gif';
    if (lower.contains('aperturas')) return 'assets/gifs/chest_fly.gif';
    if (lower.contains('fondos')) return 'assets/gifs/dips.gif';
    if (lower.contains('flexiones')) return 'assets/gifs/pushups.gif';
    if (lower.contains('dominadas')) return 'assets/gifs/pullups.gif';
    if (lower.contains('jalón')) return 'assets/gifs/lat_pulldown.gif';
    if (lower.contains('remo') && lower.contains('mancuerna')) return 'assets/gifs/dumbbell_row.gif';
    if (lower.contains('remo')) return 'assets/gifs/barbell_row.gif';
    if (lower.contains('peso muerto')) return 'assets/gifs/deadlift.gif';
    if (lower.contains('sentadilla')) return 'assets/gifs/squat.gif';
    if (lower.contains('prensa')) return 'assets/gifs/leg_press.gif';
    if (lower.contains('militar') || lower.contains('hombros')) return 'assets/gifs/overhead_press.gif';
    if (lower.contains('martillo') || lower.contains('mancuerna')) return 'assets/gifs/dumbbell_biceps_curl.gif';
    if (lower.contains('bíceps')) return 'assets/gifs/biceps_curl.gif';
    if (lower.contains('tríceps') || lower.contains('francés')) return 'assets/gifs/triceps_pushdown.gif';
    if (lower.contains('crunches') || lower.contains('plancha')) return 'assets/gifs/crunches.gif';
    return null;
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final equipmentController = TextEditingController();
    String category = 'Pecho';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Crear Ejercicio Personalizado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Ejercicio',
                      hintText: 'Ej. Press Militar',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(labelText: 'Grupo Muscular'),
                    dropdownColor: Theme.of(context).cardColor,
                    items: const [
                      DropdownMenuItem(value: 'Pecho', child: Text('Pecho')),
                      DropdownMenuItem(value: 'Espalda', child: Text('Espalda')),
                      DropdownMenuItem(value: 'Piernas', child: Text('Piernas')),
                      DropdownMenuItem(value: 'Hombros', child: Text('Hombros')),
                      DropdownMenuItem(value: 'Brazos', child: Text('Brazos')),
                      DropdownMenuItem(value: 'Core', child: Text('Core')),
                      DropdownMenuItem(value: 'Cardio', child: Text('Cardio')),
                      DropdownMenuItem(value: 'TRX', child: Text('TRX')),
                      DropdownMenuItem(value: 'Otros', child: Text('Otros')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateModal(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: equipmentController,
                    decoration: const InputDecoration(
                      labelText: 'Equipamiento (Opcional)',
                      hintText: 'Ej. Mancuernas / Polea / Peso corporal',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isNotEmpty) {
                          ref.read(exerciseListProvider.notifier).addCustomExercise(
                                name: name,
                                category: category,
                                equipment: equipmentController.text.trim().isEmpty
                                    ? null
                                    : equipmentController.text.trim(),
                              );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Guardar Ejercicio'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
