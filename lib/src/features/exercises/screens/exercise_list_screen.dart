import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                          trailing: Icon(
                            exercise.isCustom ? Icons.person_outline : Icons.fitness_center,
                            color: exercise.isCustom ? const Color(0xFF00E676) : Colors.grey,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
