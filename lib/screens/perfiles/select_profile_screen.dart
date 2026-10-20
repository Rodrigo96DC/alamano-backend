import 'package:flutter/material.dart';
import 'package:alamano2_0/screens/conductor/conductor_screen.dart';
import 'package:alamano2_0/screens/pasajero/pasajero_screen.dart';

class SelectProfileScreen extends StatelessWidget {
  const SelectProfileScreen({super.key});

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Seleccione su perfil',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ProfileButton(
                  icon: Icons.directions_car,
                  label: 'Conductor',
                  onTap: () => _navigateTo(context, const ConductorScreen()),
                ),
                const SizedBox(width: 32),
                _ProfileButton(
                  icon: Icons.person,
                  label: 'Pasajero',
                  onTap: () => _navigateTo(context, const PasajeroScreen()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 60, color: const Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D)),
          ),
        ],
      ),
    );
  }
}
