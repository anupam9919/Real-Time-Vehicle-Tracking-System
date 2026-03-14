import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vehicle/features/auth/presentation/providers/auth_providers.dart';
import 'package:vehicle/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:vehicle/routing/app_router.dart';
import 'package:vehicle/services/app_logger.dart';

final _log = AppLogger.getLogger('DriverHome');

class DriverHomePage extends ConsumerStatefulWidget {
  final String driverId;
  final String driverName;
  final String assignedVehicle;

  const DriverHomePage({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.assignedVehicle,
  });

  @override
  ConsumerState<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends ConsumerState<DriverHomePage> {
  Timer? _locationTimer;
  bool _isLive = false;
  Position? _lastPosition;
  String? _lastTimestamp;

  // Vehicle details fetched from Firebase
  String _vehicleNumber = '';
  String _driverMobileNumber = '';
  String _boardingPoint = '';
  String _destination = '';

  @override
  void initState() {
    super.initState();
    _log.info('DriverHomePage initialized for driver: ${widget.driverId}, vehicle: ${widget.assignedVehicle}');
    _fetchVehicleDetails();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _log.info('DriverHomePage disposed, timer cancelled');
    super.dispose();
  }

  Future<void> _fetchVehicleDetails() async {
    _log.info('Fetching vehicle details for: ${widget.assignedVehicle}');
    try {
      final vehicle = await ref.read(vehicleDetailsProvider(widget.assignedVehicle).future);
      if (vehicle != null && mounted) {
        setState(() {
          _vehicleNumber = vehicle.vehicleNumber;
          _driverMobileNumber = vehicle.driverMobileNumber ?? '';
          _boardingPoint = vehicle.boardingPoint ?? '';
          _destination = vehicle.destination ?? '';
        });
        _log.info('Vehicle details loaded: number=$_vehicleNumber');
      } else {
        _log.warning('No vehicle data found for: ${widget.assignedVehicle}');
      }
    } catch (e, st) {
      _log.severe('Error fetching vehicle details', e, st);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _startTransmitting() {
    _log.info('Starting GPS transmission for vehicle: ${widget.assignedVehicle}');
    final repo = ref.read(vehicleRepositoryProvider);
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await _determinePosition();
        final timestamp = DateTime.now().toIso8601String();

        await repo.updateVehicleLocation(
          vehicleId: widget.assignedVehicle,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          timestamp: timestamp,
        );

        setState(() {
          _lastPosition = position;
          _lastTimestamp = timestamp;
        });

        _log.fine('Location transmitted: lat=${position.latitude}, lng=${position.longitude}, speed=${(position.speed * 3.6).toStringAsFixed(1)} km/h');
      } catch (e) {
        _log.warning('Error transmitting location: $e');
      }
    });
  }

  void _stopTransmitting() {
    _log.info('Stopping GPS transmission');
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _toggleLive() {
    if (!_isLive && widget.assignedVehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No vehicle assigned. Contact your admin to assign a vehicle first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _startTransmitting();
      } else {
        _stopTransmitting();
      }
    });
  }

  void _triggerSOS() {
    _log.warning('SOS triggered by driver: ${widget.driverId}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS triggered!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _logout() async {
    _stopTransmitting();
    _log.info('Driver ${widget.driverId} logging out');
    await ref.read(signOutProvider).call();
    if (mounted) context.go(RoutePaths.signIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              elevation: 0,
              centerTitle: true,
              title: Text(
                'Driver Dashboard',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.2),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
                  onPressed: _logout,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -50,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6C63FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00C9FF).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Vehicle badge
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: _isLive 
                              ? Colors.greenAccent.withValues(alpha: 0.15) 
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(
                            color: _isLive 
                                ? Colors.greenAccent.withValues(alpha: 0.3) 
                                : Colors.white.withValues(alpha: 0.1),
                            width: 2
                          ),
                          boxShadow: _isLive ? [
                            BoxShadow(
                              color: Colors.greenAccent.withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2
                            )
                          ] : [],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.assignedVehicle,
                                style: GoogleFonts.outfit(
                                  fontSize: 48.0, 
                                  color: Colors.white, 
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2
                                ),
                              ),
                              if (_isLive)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.3, end: 1),
                                    const SizedBox(width: 8),
                                    Text(
                                      'TRANSMITTING', 
                                      style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2)
                                    ),
                                  ],
                                ).animate().fade().slideY(begin: 0.2),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fade().scale(begin: const Offset(0.9, 0.9)),
                  const SizedBox(height: 24.0),

                  // Info card
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.person_rounded, 'Driver', widget.driverName),
                              const SizedBox(height: 16.0),
                              if (_vehicleNumber.isNotEmpty) ...[
                                _buildInfoRow(Icons.tag_rounded, 'Vehicle Number', _vehicleNumber),
                                const SizedBox(height: 16.0),
                              ],
                              if (_driverMobileNumber.isNotEmpty) ...[
                                _buildInfoRow(Icons.phone_rounded, 'Mobile', _driverMobileNumber),
                                const SizedBox(height: 16.0),
                              ],
                              if (_boardingPoint.isNotEmpty) ...[
                                _buildInfoRow(Icons.trip_origin_rounded, 'Start Route', _boardingPoint),
                                const SizedBox(height: 16.0),
                              ],
                              if (_destination.isNotEmpty) ...[
                                _buildInfoRow(Icons.place_rounded, 'Destination', _destination),
                              ],
                              
                              const Spacer(),
                              
                              if (_lastPosition != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.gps_fixed_rounded, color: Color(0xFF00C9FF), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'LAT: ${_lastPosition!.latitude.toStringAsFixed(5)}',
                                              style: GoogleFonts.outfit(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text(
                                            'LNG: ${_lastPosition!.longitude.toStringAsFixed(5)}',
                                            style: GoogleFonts.outfit(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.speed_rounded, color: Colors.greenAccent, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SPEED: ${(_lastPosition!.speed * 3.6).toStringAsFixed(1)} KM/H',
                                            style: GoogleFonts.outfit(fontSize: 14.0, color: Colors.white70, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, color: Colors.white38, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SYNC: ${_lastTimestamp?.substring(11, 19) ?? ""}',
                                            style: GoogleFonts.outfit(fontSize: 12.0, color: Colors.white38),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ).animate().fade().slideY(begin: 0.1),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                  ),
                  const SizedBox(height: 24.0),

                  // Go Live / Stop button
                  SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _toggleLive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLive ? const Color(0xFFFF6B6B) : const Color(0xFF00C9FF),
                        foregroundColor: Colors.white,
                        elevation: _isLive ? 10 : 0,
                        shadowColor: _isLive ? const Color(0xFFFF6B6B).withValues(alpha: 0.5) : Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _isLive ? 'STOP TRANSMISSION' : 'GO LIVE',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2),
                      ),
                    ).animate(target: _isLive ? 1 : 0).shimmer(duration: 1.seconds, color: Colors.white24),
                  ).animate().fade(delay: 400.ms).slideY(begin: 0.1),

                  // SOS button (only when live)
                  if (_isLive) ...[
                    const SizedBox(height: 16.0),
                    SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: _triggerSOS,
                        icon: const Icon(Icons.warning_amber_rounded, size: 28),
                        label: Text('EMERGENCY SOS', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFFFF6B6B),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scaleXY(begin: 1.0, end: 1.02),
                    ).animate().fade().slideY(begin: 0.1),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.outfit(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
