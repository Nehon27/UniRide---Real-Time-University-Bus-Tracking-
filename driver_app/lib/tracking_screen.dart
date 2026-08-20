import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'config.dart';
import 'main.dart';

enum LocationReadiness {
  checking,
  serviceDisabled, // GPS toggle is off on the phone
  permissionDenied, // asked once, user said no (can ask again)
  permissionDeniedForever, // user must go to app settings manually
  ready,
}

class TrackingScreen extends StatefulWidget {
  final int driverId;
  final String fullName;
  final String busName;

  const TrackingScreen({
    super.key,
    required this.driverId,
    required this.fullName,
    required this.busName,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with WidgetsBindingObserver {
  LocationReadiness _readiness = LocationReadiness.checking;
  bool _isTracking = false;
  Timer? _timer;
  Position? _lastPosition;
  int _updatesSent = 0;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkReadiness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // When the driver comes back from the phone's Settings app (after turning on
  // GPS or granting permission there), automatically re-check instead of
  // making them tap a button again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _readiness != LocationReadiness.ready) {
      _checkReadiness();
    }
  }

  Future<void> _checkReadiness() async {
    setState(() => _readiness = LocationReadiness.checking);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _readiness = LocationReadiness.serviceDisabled);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // This triggers the native Android/iOS permission dialog.
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() => _readiness = LocationReadiness.permissionDenied);
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _readiness = LocationReadiness.permissionDeniedForever);
      return;
    }

    setState(() => _readiness = LocationReadiness.ready);
  }

  // Opens the phone's system "Location" settings screen so the driver can
  // flip the GPS toggle on. Coming back to the app re-triggers the check
  // automatically via didChangeAppLifecycleState above.
  Future<void> _promptEnableLocationService() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _promptOpenAppSettings() async {
    await Geolocator.openAppSettings();
  }

  void _startTracking() {
    if (_readiness != LocationReadiness.ready) return;
    setState(() {
      _isTracking = true;
      _lastError = null;
    });

    _sendOnce(); // send immediately, then every N seconds
    _timer = Timer.periodic(
      const Duration(seconds: AppConfig.locationIntervalSeconds),
      (_) => _sendOnce(),
    );
  }

  // Pulls the current GPS position only (latitude/longitude) and forwards it —
  // no route, no speed, no extra data collected.
  Future<void> _sendOnce() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final ok = await ApiService.sendLocation(widget.driverId, position.latitude, position.longitude);

      if (!mounted) return;
      setState(() {
        _lastPosition = position;
        if (ok) {
          _updatesSent++;
          _lastError = null;
        } else {
          _lastError = 'Server did not accept the last update';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _lastError = 'Could not get GPS location — is GPS still on?');
      // GPS may have been switched off mid-trip; re-check so the UI reflects it.
      _checkReadiness();
    }
  }

  Future<void> _stopTracking() async {
    _timer?.cancel();
    setState(() => _isTracking = false);
    await ApiService.stopTracking(widget.driverId);
  }

  Future<void> _logout() async {
    if (_isTracking) {
      await _stopTracking();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  String get _statusText {
    switch (_readiness) {
      case LocationReadiness.checking:
        return 'Checking location status...';
      case LocationReadiness.serviceDisabled:
        return 'Your device location (GPS) is turned off. Turn it on to start sharing your location.';
      case LocationReadiness.permissionDenied:
        return 'UniRide needs location permission to track your bus. Tap below to allow it.';
      case LocationReadiness.permissionDeniedForever:
        return 'Location permission was permanently denied. Open app settings and allow location manually.';
      case LocationReadiness.ready:
        return _isTracking ? 'Sharing live location...' : 'Ready. Tap "Start Trip" to begin sharing your location.';
    }
  }

  // The single primary button changes behavior depending on what's blocking us.
  VoidCallback? get _primaryAction {
    switch (_readiness) {
      case LocationReadiness.checking:
        return null;
      case LocationReadiness.serviceDisabled:
        return _promptEnableLocationService;
      case LocationReadiness.permissionDenied:
        return _checkReadiness; // re-asks for permission
      case LocationReadiness.permissionDeniedForever:
        return _promptOpenAppSettings;
      case LocationReadiness.ready:
        return _isTracking ? _stopTracking : _startTracking;
    }
  }

  String get _primaryLabel {
    switch (_readiness) {
      case LocationReadiness.checking:
        return 'Checking...';
      case LocationReadiness.serviceDisabled:
        return 'Turn On Location';
      case LocationReadiness.permissionDenied:
        return 'Allow Location Access';
      case LocationReadiness.permissionDeniedForever:
        return 'Open App Settings';
      case LocationReadiness.ready:
        return _isTracking ? 'Stop Trip' : 'Start Trip';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool blocked = _readiness != LocationReadiness.ready;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        title: const Text('UniRide Driver'),
        backgroundColor: const Color(0xFF1A3C6E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Bus: ${widget.busName}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Big status circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blocked
                      ? const Color(0xFFFDECEA)
                      : (_isTracking ? const Color(0xFFE3F6E5) : const Color(0xFFEFEFEF)),
                  border: Border.all(
                    color: blocked
                        ? const Color(0xFFC0392B)
                        : (_isTracking ? const Color(0xFF2E7D32) : Colors.grey.shade400),
                    width: 3,
                  ),
                ),
                child: Icon(
                  blocked
                      ? Icons.location_off
                      : (_isTracking ? Icons.gps_fixed : Icons.gps_off),
                  size: 64,
                  color: blocked
                      ? const Color(0xFFC0392B)
                      : (_isTracking ? const Color(0xFF2E7D32) : Colors.grey),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                _statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),

              if (_lastPosition != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Lat: ${_lastPosition!.latitude.toStringAsFixed(5)}, '
                  'Lng: ${_lastPosition!.longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Updates sent: $_updatesSent',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],

              if (_lastError != null) ...[
                const SizedBox(height: 10),
                Text(_lastError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _primaryAction,
                  icon: Icon(_isTracking && !blocked ? Icons.stop_circle : Icons.play_circle_fill),
                  label: Text(_primaryLabel, style: const TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking && !blocked ? const Color(0xFFC0392B) : const Color(0xFF1A3C6E),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
