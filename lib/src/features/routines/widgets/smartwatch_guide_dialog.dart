import 'package:flutter/material.dart';

class SmartwatchGuideDialog extends StatelessWidget {
  const SmartwatchGuideDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SmartwatchGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.watch, color: Color(0xFF00E676), size: 28),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Guía de Sincronización para Smartwatches',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Para recibir avisos de series con vibración en la muñeca y controlar tu rutina desde tu reloj, asegúrate de tener activadas las notificaciones de Gymcel en la aplicación de tu marca:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 16),

            _buildBrandItem(
              context,
              brand: 'Xiaomi / Mi Band',
              instruction: 'Abre Mi Fitness ➔ Dispositivo ➔ Notificaciones de aplicaciones ➔ Activa Gymcel.',
              icon: Icons.watch_outlined,
            ),
            _buildBrandItem(
              context,
              brand: 'Amazfit',
              instruction: 'Abre Zepp ➔ Perfil ➔ Dispositivo ➔ Notificaciones de la app ➔ Activa Gymcel.',
              icon: Icons.watch_outlined,
            ),
            _buildBrandItem(
              context,
              brand: 'Huawei Watch',
              instruction: 'Abre Huawei Health (Salud) ➔ Dispositivos ➔ Notificaciones ➔ Activa Gymcel.',
              icon: Icons.watch_outlined,
            ),
            _buildBrandItem(
              context,
              brand: 'Garmin',
              instruction: 'Abre Garmin Connect ➔ Ajustes ➔ Notificaciones de teléfono ➔ Activa Gymcel.',
              icon: Icons.watch_outlined,
            ),
            _buildBrandItem(
              context,
              brand: 'Samsung / Wear OS',
              instruction: 'Se sincroniza automáticamente a través de la app Galaxy Wearable.',
              icon: Icons.watch_outlined,
            ),
            const SizedBox(height: 8),
            const Text(
              '⚡ Consejo: Si usas música (Spotify/YouTube Music), podrás controlar la música y Gymcel simultáneamente desde tu reloj.',
              style: TextStyle(fontSize: 12, color: Color(0xFF00E676), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido, ¡A Entrenar!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandItem(
    BuildContext context, {
    required String brand,
    required String instruction,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF00E676)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.white),
                children: [
                  TextSpan(
                    text: '$brand: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                  ),
                  TextSpan(text: instruction),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
