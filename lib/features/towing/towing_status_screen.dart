import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme_provider.dart';
import '../../../components/osm_map_widget.dart';

class TowingStatusScreen extends StatefulWidget {
  final String? requestId;
  const TowingStatusScreen({super.key, this.requestId});

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

  LatLng _userLoc = const LatLng(6.9271, 79.8612); // Default
  LatLng _driverLoc = const LatLng(6.9371, 79.8712); // Default
  
  StreamSubscription? _requestSub;
  StreamSubscription? _driverSub;
  
  String _driverName = "Searching...";
  String _driverPlate = "";
  String _etr = "---";
  String _paymentStatus = 'pending';
  num _totalAmount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.requestId != null) {
      _listenToRequest();
    } else {
      // Demo mode if no ID provided
      _startMockProgress();
    }
  }

  void _listenToRequest() {
    _requestSub = FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data()!;
        final status = data['status'] ?? 'pending';
        final userLoc = data['userLocation'] as Map<String, dynamic>?;
        final pStatus = data['paymentStatus'] ?? 'pending';
        final amount = data['basePrice'] ?? 0;
        
        setState(() {
          _paymentStatus = pStatus;
          _totalAmount = amount;
          if (userLoc != null) {
            _userLoc = LatLng(userLoc['lat'], userLoc['lng']);
          }
          
          switch (status) {
            case 'pending':
              _currentStep = 0;
              break;
            case 'accepted':
              _currentStep = 1;
              break;
            case 'arriving':
              _currentStep = 2;
              break;
            case 'picked_up':
              _currentStep = 3;
              break;
            case 'completed':
              _currentStep = 3; // Stay at last step or pop
              break;
          }

          if (data['mechanicId'] != null) {
            _listenToDriver(data['mechanicId']);
            _driverName = data['mechanicName'] ?? "Driver Assigned";
          }
        });
      }
    });
  }

  void _listenToDriver(String driverId) {
    _driverSub?.cancel();
    _driverSub = FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data()!;
        final roles = data['roles'] as Map<String, dynamic>?;
        final towRole = roles?['tow'] ?? roles?['mechanic']; // Fix: use 'tow' instead of 'tow owner'
        
        if (towRole != null) {
          final loc = towRole['location'] as Map<String, dynamic>?;
          setState(() {
            if (loc != null) {
              _driverLoc = LatLng(loc['lat'], loc['lng']);
            }
            _driverPlate = towRole['plate'] ?? "";
            
            // Calculate ETR based on distance
            final Distance distance = const Distance();
            final double meter = distance.as(LengthUnit.Meter, _userLoc, _driverLoc);
            final int mins = (meter / 300).toInt(); // Approx 20km/h in traffic
            _etr = "$mins MIN";
          });
        }
      }
    });
  }

  // Fallback Demo Logic
  void _startMockProgress() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentStep < _statuses.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _requestSub?.cancel();
    _driverSub?.cancel();
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

          // 3. Status Dashboard
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Status: ${_statuses[_currentStep]}",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Driver: $_driverName ${_driverPlate.isNotEmpty ? '($_driverPlate)' : ''}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ETR: $_etr",
                          style: const TextStyle(
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
                  if (_currentStep == 2 && _paymentStatus == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (widget.requestId != null) {
                            await FirebaseFirestore.instance
                                .collection('requests')
                                .doc(widget.requestId)
                                .update({'paymentStatus': 'paid'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Payment Successful!")),
                            );
                          }
                        },
                        icon: const Icon(Icons.payment),
                        label: Text("PAY Rs. $_totalAmount"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  
                  if (_paymentStatus == 'paid')
                     Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text("Payment Confirmed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
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
                      if (_paymentStatus == 'pending') ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (widget.requestId != null) {
                                FirebaseFirestore.instance
                                    .collection('requests')
                                    .doc(widget.requestId)
                                    .update({'status': 'cancelled'});
                              }
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
