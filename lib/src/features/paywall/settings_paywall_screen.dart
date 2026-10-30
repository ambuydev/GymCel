import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/db_helper.dart';
import '../auth/providers/auth_provider.dart';
import '../auth/screens/auth_dialog.dart';
import '../routines/widgets/smartwatch_guide_dialog.dart';

final isPremiumProvider = StateNotifierProvider<PremiumNotifier, bool>((ref) {
  return PremiumNotifier()..loadStatus();
});

class PremiumNotifier extends StateNotifier<bool> {
  PremiumNotifier() : super(false);

  Future<void> loadStatus() async {
    final status = await DBHelper.instance.getSetting('is_premium');
    state = status == 'true';
  }

  Future<void> togglePremium(bool value) async {
    await DBHelper.instance.setSetting('is_premium', value ? 'true' : 'false');
    state = value;
  }
}

// Global Rest Timer Setting Provider
final globalRestSecondsProvider = StateNotifierProvider<GlobalRestNotifier, int>((ref) {
  return GlobalRestNotifier()..loadRestSetting();
});

class GlobalRestNotifier extends StateNotifier<int> {
  GlobalRestNotifier() : super(90);

  Future<void> loadRestSetting() async {
    final val = await DBHelper.instance.getSetting('rest_timer_seconds', defaultValue: '90');
    state = int.tryParse(val) ?? 90;
  }

  Future<void> updateRestSetting(int newSeconds) async {
    await DBHelper.instance.setSetting('rest_timer_seconds', newSeconds.toString());
    state = newSeconds;
  }
}

// Weight Unit Setting Provider
final weightUnitProvider = StateNotifierProvider<WeightUnitNotifier, String>((ref) {
  return WeightUnitNotifier()..loadUnitSetting();
});

class WeightUnitNotifier extends StateNotifier<String> {
  WeightUnitNotifier() : super('kg');

  Future<void> loadUnitSetting() async {
    final val = await DBHelper.instance.getSetting('weight_unit', defaultValue: 'kg');
    state = val;
  }

  Future<void> updateUnitSetting(String newUnit) async {
    await DBHelper.instance.setSetting('weight_unit', newUnit);
    state = newUnit;
  }
}

class SettingsPaywallScreen extends ConsumerWidget {
  const SettingsPaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    final authState = ref.watch(authStateProvider);
    final globalRest = ref.watch(globalRestSecondsProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    final user = authState.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes y Nube Premium'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Card(
              color: isPremium ? const Color(0xFF1E2822) : const Color(0xFF28241E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isPremium ? const Color(0xFF00E676) : Colors.orangeAccent,
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isPremium ? Icons.workspace_premium : Icons.star_border,
                      size: 40,
                      color: isPremium ? const Color(0xFF00E676) : Colors.orangeAccent,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium ? 'Suscripción Premium Activa' : 'Plan Gratuito Local',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isPremium ? const Color(0xFF00E676) : Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPremium
                                ? 'Historial ilimitado y copia de seguridad en la nube activada.'
                                : 'Almacenamiento local SQLite con historial de 30 días.',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cloud Auth & Sync Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_sync, color: Color(0xFF00E676)),
                        const SizedBox(width: 8),
                        Text(
                          user != null ? 'Cuenta de Nube Conectada' : 'Respaldo en la Nube',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user != null
                          ? 'Iniciado como: ${user.email}'
                          : 'Conéctate a Firebase para mantener tu historial seguro en la nube.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    if (user == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AuthDialog(),
                            );
                          },
                          icon: const Icon(Icons.login),
                          label: const Text('Conectar Cuenta Firebase'),
                        ),
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final sync = ref.read(syncServiceProvider);
                                  await sync.backupLocalToCloud(user.uid);
                                  final restored = await sync.restoreCloudToLocal(user.uid);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Sincronización completada ($restored sesiones restauradas).'),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error al sincronizar: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.sync),
                              label: const Text('Sincronizar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () async {
                              await ref.read(authServiceProvider).signOut();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                            child: const Text('Salir'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Demo Toggle Switch for Premium status
            Card(
              child: SwitchListTile(
                title: const Text(
                  'Modo Premium (Simulación)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Activa o desactiva la suscripción para probar la sincronización e historial ilimitado.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                value: isPremium,
                activeThumbColor: const Color(0xFF00E676),
                onChanged: (val) {
                  ref.read(isPremiumProvider.notifier).togglePremium(val);
                },
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Preferencias de Entrenamiento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Interactive Settings List Card
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.timer_outlined, color: Color(0xFF00E676)),
                    title: const Text('Descanso Global por Defecto'),
                    subtitle: Text('$globalRest Segundos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRestTimerDialog(context, ref, globalRest),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.scale_outlined, color: Color(0xFF00E676)),
                    title: const Text('Unidad de Peso'),
                    subtitle: Text(weightUnit == 'kg' ? 'Kilogramos (kg)' : 'Libras (lbs)'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showWeightUnitDialog(context, ref, weightUnit),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.watch_outlined, color: Color(0xFF00E676)),
                    title: const Text('Configurar Smartwatch y Relojes'),
                    subtitle: const Text('Guía para Xiaomi, Amazfit, Huawei, Garmin, Samsung'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => SmartwatchGuideDialog.show(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Comparativa de Planes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Plan Comparison Table Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _featureRow('Uso 100% Offline e Inmediato', true, true),
                    const Divider(color: Colors.white10),
                    _featureRow('Creador de Rutinas Ilimitado', true, true),
                    const Divider(color: Colors.white10),
                    _featureRow('Biblioteca de Ejercicios + Personalizados', true, true),
                    const Divider(color: Colors.white10),
                    _featureRow('Temporizador de Descanso Automático', true, true),
                    const Divider(color: Colors.white10),
                    _featureRow('Historial de Entrenamientos', '30 Días Local', 'Ilimitado'),
                    const Divider(color: Colors.white10),
                    _featureRow('Copia de Seguridad en la Nube (Firestore)', false, true),
                    const Divider(color: Colors.white10),
                    _featureRow('Sincronización entre Múltiples Dispositivos', false, true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showRestTimerDialog(BuildContext context, WidgetRef ref, int currentVal) {
    final options = [30, 45, 60, 90, 120, 180, 240, 300];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Seleccionar Descanso Global'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((secs) {
                final isSel = secs == currentVal;
                return ListTile(
                  title: Text('$secs Segundos'),
                  trailing: isSel ? const Icon(Icons.check, color: Color(0xFF00E676)) : null,
                  onTap: () {
                    ref.read(globalRestSecondsProvider.notifier).updateRestSetting(secs);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showWeightUnitDialog(BuildContext context, WidgetRef ref, String currentUnit) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Seleccionar Unidad de Peso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Kilogramos (kg)'),
                trailing: currentUnit == 'kg' ? const Icon(Icons.check, color: Color(0xFF00E676)) : null,
                onTap: () {
                  ref.read(weightUnitProvider.notifier).updateUnitSetting('kg');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: const Text('Libras (lbs)'),
                trailing: currentUnit == 'lbs' ? const Icon(Icons.check, color: Color(0xFF00E676)) : null,
                onTap: () {
                  ref.read(weightUnitProvider.notifier).updateUnitSetting('lbs');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _featureRow(String name, dynamic freeValue, dynamic premiumValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _renderValue(freeValue)),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _renderValue(premiumValue, isPremium: true)),
          ),
        ],
      ),
    );
  }

  Widget _renderValue(dynamic val, {bool isPremium = false}) {
    if (val is bool) {
      return val
          ? Icon(Icons.check,
              color: isPremium ? const Color(0xFF00E676) : Colors.white70, size: 18)
          : const Icon(Icons.close, color: Colors.grey, size: 18);
    }
    return Text(
      '$val',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: isPremium ? const Color(0xFF00E676) : Colors.grey,
      ),
    );
  }
}
