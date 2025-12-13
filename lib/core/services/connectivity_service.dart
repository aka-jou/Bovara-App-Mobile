import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();
  bool _isConnected = true;

  ConnectivityService() {
    _initConnectivity();
    // ← CAMBIO: Ahora recibe List<ConnectivityResult>
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  bool get isConnected => _isConnected;
  Stream<bool> get connectivityStream => _connectionStatusController.stream;

  Future<void> _initConnectivity() async {
    try {
      // ← CAMBIO: checkConnectivity() ahora devuelve List<ConnectivityResult>
      final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      print('Error checking connectivity: $e');
      _isConnected = false;
    }
  }

  // ← CAMBIO: Ahora recibe List<ConnectivityResult>
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;

    // Hay conexión si al menos uno de los resultados NO es "none"
    _isConnected = results.isNotEmpty &&
        !results.every((result) => result == ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      _connectionStatusController.add(_isConnected);
    }
  }

  void dispose() {
    _connectionStatusController.close();
  }
}
