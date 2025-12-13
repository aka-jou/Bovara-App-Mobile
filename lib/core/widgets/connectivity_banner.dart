import 'package:flutter/material.dart';

/// Banner que muestra el estado de conectividad a internet
/// Se muestra en verde cuando hay conexión y en naranja cuando no hay
class ConnectivityBanner extends StatelessWidget {
  final bool isConnected;

  const ConnectivityBanner({
    Key? key,
    required this.isConnected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      color: isConnected ? const Color(0xFF2D5F3F) : Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isConnected
                    ? 'Conectado – sincronización disponible'
                    : 'Sin conexión – modo offline activo',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
