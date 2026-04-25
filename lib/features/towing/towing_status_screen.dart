import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../../../theme_provider.dart';
import '../../../components/osm_map_widget.dart';

class TowingStatusScreen extends StatefulWidget {
  const TowingStatusScreen({super.key});

  @override
  State<TowingStatusScreen> createState() => _TowingStatusScreenState();
}

class _TowingStatusScreenState extends State<TowingStatusScreen> {
  int _currentStep = 0;
  final List<String> _statuses = [
    "Request Received",
    "Driver Assigned",
    "Truck En Route",
    "Vehicle Picked Up"
  ];

  // Mock location for user and driver
  final LatLng _userLoc = const LatLng(6.9271, 79.8612); // Colombo example
  LatLng _driverLoc = const LatLng(6.9371, 79.8712);
  
  Timer? _statusTimer;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    _startMockProgress();
  }

  void _startMockProgress() {
    // Progress through steps every 5 seconds for demo
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentStep < _statuses.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });

    // Move driver closer to user
    _moveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_currentStep >= 1 && _currentStep < 3) {
        setState(() {
          double latDiff = (_userLoc.latitude - _driverLoc.latitude) * 0.01;
          double lngDiff = (_userLoc.longitude - _driverLoc.longitude) * 0.01;
          _driverLoc = LatLng(_driverLoc.latitude + latDiff, _driverLoc.longitude + lngDiff);
        });
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _moveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Live Map
          Positioned.fill(
            child: OsmMapWidget(
              center: _userLoc,
              zoom: 14,
              markers: [
                Marker(
                  point: _userLoc,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                ),
                Marker(
                  point: _driverLoc,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.local_shipping, color: AppColors.emergencyRed, size: 40),
                ),
              ],
            ),
          ),

          // 2. Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: dark ? AppColors.darkSurface : Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: dark ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Status Dashboard (Bottom Sheet-like)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Status: ${_statuses[_currentStep]}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: dark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Driver: John Doe (TOW-4502)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "ETR: 8 MIN",
                          style: TextStyle(
                            color: AppColors.emergencyRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Status Stepper
                  Expanded(
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _statuses.length,
                      itemBuilder: (context, index) {
                        bool isCompleted = index < _currentStep;
                        bool isActive = index == _currentStep;
                        
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isCompleted || isActive ? AppColors.emergencyRed : Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: isCompleted 
                                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                                    : (isActive ? Container(
                                        margin: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                      ) : null),
                                ),
                                if (index < _statuses.length - 1)
                                  Container(
                                    width: 2,
                                    height: 30,
                                    color: isCompleted ? AppColors.emergencyRed : Colors.grey[300],
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              _statuses[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? (dark ? Colors.white : Colors.black) : Colors.grey[500],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Mock contact
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Calling driver...")),
                            );
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text("CONTACT"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emergencyRed,
                            side: const BorderSide(color: AppColors.emergencyRed),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close),
                          label: const Text("CANCEL"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
