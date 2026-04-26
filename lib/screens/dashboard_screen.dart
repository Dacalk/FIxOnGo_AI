import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/dashboard_header.dart';
import '../components/stat_card.dart';
import '../components/quick_action_card.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import '../components/osm_map_widget.dart';
import '../components/incoming_job_overlay.dart';
import '../services/location_service.dart';
import '../services/test_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'mechanic_shop_screen.dart';
import 'garage_screen.dart';
import 'payment_history_screen.dart';
import 'profile_screen.dart';
import 'delivery_history_screen.dart';
import 'delivery_jobs_screen.dart';

/// Main dashboard screen with bottom navigation.
/// Renders role-specific content based on the user's role.
class DashboardScreen extends StatefulWidget {
  final String? role;

  const DashboardScreen({super.key, this.role});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Common
  String userName = '';
  String userEmail = '';
  String userPhone = '';
  String userPhotoUrl = '';
  bool isLoading = true;

  // Role-specific data map
  Map<String, dynamic> allRoles = {};
  Map<String, dynamic> roleData = {};
  String? currentRole;
  LatLng? _userLocation;

  StreamSubscription? _requestSubscription;
  StreamSubscription? _deliverySubscription;
  Timer? _posTimer;
  String? _lastDialogRequestId;
  String? _lastDialogDeliveryId;
  bool _isNavigating = false;
  bool _isOverlayShown = false;
  bool _isInitialized = false;

  // Real-time data streams
  Stream<List<Map<String, dynamic>>>? _ongoingRequestsStream;
  Stream<List<Map<String, dynamic>>>? _paymentHistoryStream;
  Stream<List<Map<String, dynamic>>>? _availableJobsStream;
  bool _isMechanicActive = true;
  bool _isDeliveryActive = true;
  Stream<List<Map<String, dynamic>>>? _mechanicIncomingRequestsStream;

  @override
  void initState() {
    super.initState();
    currentRole = widget.role; // Initial value
    loadUserData();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final loc = await LocationService.instance.getCurrentLatLng();
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _userLocation = loc);
          }
        });
      }
    } catch (e) {
      print("Error fetching dashboard location: $e");
    }
  }

  Future<void> loadUserData() async {
    if (_isInitialized) return;
    _isInitialized = true;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String role = widget.role ?? 'User';

    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final rolesMap = data?['roles'] as Map<String, dynamic>? ?? {};

        // 🧠 DYNAMIC ROLE RESOLUTION
        // If we were passed "User" (the default) but the user has other roles,
        // and "User" isn't actually one of them, pick the first available role.
        if (role == 'User' &&
            !rolesMap.containsKey('user') &&
            rolesMap.isNotEmpty) {
          role = rolesMap.keys.first;
        }

        // Check both lowercase and original casing
        Map<String, dynamic> rd = {};
        if (rolesMap.containsKey(role.toLowerCase())) {
          rd = rolesMap[role.toLowerCase()] as Map<String, dynamic>? ?? {};
        } else if (rolesMap.containsKey(role)) {
          rd = rolesMap[role] as Map<String, dynamic>? ?? {};
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              allRoles = rolesMap;
              // Update the localized role if we changed it
              currentRole = role;
              userName = rd['fullName']?.toString().isNotEmpty == true
                  ? rd['fullName']
                  : user.displayName ?? 'User';
              userEmail = data?['email']?.toString().isNotEmpty == true
                  ? data!['email']
                  : user.email ?? '';
              userPhone = data?['phone']?.toString().isNotEmpty == true
                  ? data!['phone']
                  : user.phoneNumber ?? '';
              roleData = rd;
              userPhotoUrl =
                  data?['photoUrl']?.toString() ?? user.photoURL ?? '';
              _isMechanicActive = rd['isActive'] ?? true;
              isLoading = false;
            });

            // 🟢 INIT DATA STREAMS FOR USER
            if (currentRole?.toLowerCase() == 'user' ||
                rolesMap.containsKey('user')) {
              _initUserDataStreams(user.uid);
            }

            // 🔧 ALWAYS START MECHANIC SERVICES IF ROLE EXISTS
            final isMechanic = rolesMap.containsKey('mechanic') ||
                userEmail == 'mock@fixongo.test';

            if (isMechanic) {
              if (userEmail == 'mock@fixongo.test' && _userLocation != null) {
                TestService.instance.cleanupMocks();
                TestService.instance.removeDuplicateMocks(user.uid);
                TestService.instance
                    .makeMeMockMechanic(user.uid, _userLocation!);
              }
              _initMechanicServices(user.uid);
              _initMechanicDataStreams(user.uid);
            }

            // 🚚 INIT DELIVERY STREAMS IF DELIVERY ROLE EXISTS
            if (rolesMap.containsKey('delivery') ||
                role.toLowerCase() == 'delivery') {
              _initDeliveryDataStreams(user.uid);
              _isDeliveryActive =
                  (rolesMap['delivery']?['isActive'] as bool?) ?? true;
            }
          }
        });
      } else {
        // No Firestore doc — use Google profile data
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              userName = user.displayName ?? 'User';
              userEmail = user.email ?? '';
              userPhone = user.phoneNumber ?? '';
              userPhotoUrl = user.photoURL ?? '';
              isLoading = false;
            });

            // 🔧 START MECHANIC SERVICES
            if (role.toLowerCase() == 'mechanic' ||
                user.email == 'mock@fixongo.test') {
              _initMechanicServices(user.uid);
              _initMechanicDataStreams(user.uid);
            }
          }
        });
      }
    } catch (e) {
      print("Dashboard load error: ${e.toString()}");
      // Fallback to Google profile on any error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            userName = user.displayName ?? 'User';
            userEmail = user.email ?? '';
            userPhotoUrl = user.photoURL ?? '';
            isLoading = false;
          });
        }
      });
    }
  }

  // Helper to get a role field with a fallback
  String _rd(String key, [String fallback = '']) =>
      roleData[key]?.toString() ?? fallback;

  Future<void> _toggleMechanicActive(bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Text('Updating status to ${value ? 'Online' : 'Offline'}...'),
          ],
        ),
        duration: const Duration(seconds: 1),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isMechanicActive = value);
      }
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'roles.mechanic.isActive': value,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating status: $e")),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isMechanicActive = !value);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = currentRole ?? widget.role ?? 'User';
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF5F8FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildDashboardContent(role, dark),
                role.toLowerCase() == 'mechanic'
                    ? const MechanicShopScreen(isEmbedded: true)
                    : role.toLowerCase() == 'delivery'
                        ? const DeliveryJobsScreen(isEmbedded: true)
                        : const GarageScreen(isEmbedded: true),
                role.toLowerCase() == 'delivery'
                    ? const DeliveryHistoryScreen(isEmbedded: true)
                    : const PaymentHistoryScreen(isEmbedded: true),
                ProfileScreen(
                  isEmbedded: true,
                  role: role,
                  userData: {
                    'fullName': userName,
                    'email': userEmail,
                    'photoUrl': userPhotoUrl,
                  },
                ),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(dark),
    );
  }

  void _switchRole(String newRole) {
    if (newRole == currentRole) return;
    setState(() => isLoading = true);

    final rd = allRoles[newRole.toLowerCase()] ?? allRoles[newRole] ?? {};

    // Simulate short delay for smoothness
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          currentRole = newRole;
          roleData = rd;
          userName = rd['fullName']?.toString().isNotEmpty == true
              ? rd['fullName']
              : FirebaseAuth.instance.currentUser?.displayName ?? 'User';
          _currentIndex = 0; // Back to dashboard
          _isInitialized = false; // Allow loadUserData to run again
        });
        loadUserData();
      }
    });
  }

  // ─── MECHANIC LOGIC ───────────────────────────────────────────

  void _initMechanicServices(String uid) {
    // 1. Update location periodically
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final loc = await LocationService.instance.getCurrentLatLng();
      // Use dot notation to avoid overwriting the whole role map
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'roles.mechanic.location': {'lat': loc.latitude, 'lng': loc.longitude},
        'roles.mechanic.lastSeen': FieldValue.serverTimestamp(),
      });
    });

    // 2. Listen for requests
    _requestSubscription?.cancel();
    _requestSubscription = FirebaseFirestore.instance
        .collection('requests')
        .where('mechanicId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty) {
        final req = snap.docs.first.data();
        final reqId = snap.docs.first.id;

        if (_lastDialogRequestId != reqId && !_isOverlayShown) {
          _lastDialogRequestId = reqId;
          req['id'] = reqId;
          _showNewRequestDialog(req);
        }
      }
    });
  }

  void _initUserDataStreams(String uid) {
    // Ongoing Requests: pending, accepted, arriving
    _ongoingRequestsStream = FirebaseFirestore.instance
        .collection('requests')
        .where('userId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'arriving'])
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

    // Payment History: from formal payments collection
    _paymentHistoryStream = FirebaseFirestore.instance
        .collection('payments')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  void _initMechanicDataStreams(String uid) {
    // For mechanic earnings/history
    _paymentHistoryStream = FirebaseFirestore.instance
        .collection('payments')
        .where('mechanicId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

    // Incoming Requests for mechanic: status == pending
    _mechanicIncomingRequestsStream = FirebaseFirestore.instance
        .collection('requests')
        .where('mechanicId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  void _initDeliveryDataStreams(String uid) {
    // Active deliveries (accepted or en_route — assigned to this driver)
    _ongoingRequestsStream = FirebaseFirestore.instance
        .collection('deliveries')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['accepted', 'en_route'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    // Completed deliveries — for earnings stats
    _paymentHistoryStream = FirebaseFirestore.instance
        .collection('deliveries')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    // Unassigned jobs from Seller or Mechanic
    _availableJobsStream = FirebaseFirestore.instance
        .collection('deliveries')
        .where('status', isEqualTo: 'pending')
        .where('sourceRole', whereIn: ['seller', 'mechanic'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());

    // Listen for incoming delivery jobs to show pop-up
    _deliverySubscription?.cancel();
    _deliverySubscription = FirebaseFirestore.instance
        .collection('deliveries')
        .where('status', isEqualTo: 'pending')
        .where('sourceRole', whereIn: ['seller', 'mechanic'])
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty && _isDeliveryActive) {
        // Iterate to find a job we haven't popped up for yet
        for (var doc in snap.docs) {
          final reqId = doc.id;
          final req = doc.data();
          if (_lastDialogDeliveryId != reqId && !_isOverlayShown) {
            _lastDialogDeliveryId = reqId;
            req['id'] = reqId;
            _showNewDeliveryDialog(req);
            break;
          }
        }
      }
    });
  }

  // ─────────────────────────────────────────────
  //  DELIVERY: Available Jobs Section
  // ─────────────────────────────────────────────
  Widget _availableDeliveryJobsSection(bool dark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _availableJobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No available jobs right now.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          );
        }
        return Column(
          children: jobs.map((job) => _deliveryJobCard(job, dark)).toList(),
        );
      },
    );
  }

  Widget _deliveryJobCard(Map<String, dynamic> job, bool dark) {
    final isSeller = job['sourceRole'] == 'seller';
    final accent = isSeller ? Colors.orange : Colors.blue;
    final badge = isSeller ? '🛒 Seller' : '🔧 Mechanic';
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSeller ? Icons.shopping_bag : Icons.build_circle,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job['itemName'] ?? 'Item',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${job['pickupAddress'] ?? 'Pickup'} → ${job['dropAddress'] ?? 'Drop'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Rs. ${job['earnings'] ?? 0} fee',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('deliveries')
                    .doc(job['id'])
                    .update({
                  'driverId': uid,
                  'driverName': userName,
                  'status': 'accepted',
                  'acceptedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pushNamed(context, '/active-delivery',
                      arguments: job['id']);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Accept',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }


  void _showNewRequestDialog(Map<String, dynamic> req) {
    if (_isOverlayShown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isOverlayShown = true);
      }
    });

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomingJobOverlay(
        requestData: req,
        onReject: () async {
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(req['id'])
              .update({'status': 'rejected'});
          if (mounted) {
            Navigator.pop(context);
          }
        },
        onAccept: () async {
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(req['id'])
              .update({
            'status': 'accepted',
            'acceptedAt': FieldValue.serverTimestamp(),
          });
          _requestSubscription?.cancel();
          _lastDialogRequestId = null;

          if (mounted) {
            Navigator.pop(context);
          }
          // Navigate to mechanic tracking screen
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (_isNavigating) return;
                _isNavigating = true;
                Navigator.pushNamed(context, '/mechanic-nav-to-user',
                    arguments: req['id']);
              }
            });
          }
        },
      ),
    ).then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _isOverlayShown = false);
          }
        });
      }
    });
  }

  void _showNewDeliveryDialog(Map<String, dynamic> req) {
    if (_isOverlayShown) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isOverlayShown = true);
      }
    });

    // Map delivery fields to IncomingJobOverlay expected format
    final isSeller = req['sourceRole'] == 'seller';
    final mappedReq = {
      ...req,
      'userAddress': req['pickupAddress'] ?? 'Nearby Pickup',
      'userName': req['itemName'] ?? 'Delivery Request',
      'serviceType': isSeller ? 'Store Pickup' : 'Mechanic Request',
    };
    if (req['pickupLat'] != null && req['pickupLng'] != null) {
      mappedReq['userLocation'] = {
        'lat': req['pickupLat'],
        'lng': req['pickupLng']
      };
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IncomingJobOverlay(
        requestData: mappedReq,
        onReject: () async {
          // Since it's a broadcast job, rejecting just dismisses it for this driver.
          // In a real app we might store an array of drivers who skipped it.
          if (mounted) Navigator.pop(context);
        },
        onAccept: () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid == null) return;

          final dData = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          final rd = (dData.data()?['roles'] ?? {})['delivery'] ?? {};
          final driverName = rd['fullName'] ?? dData.data()?['fullName'] ?? 'Driver';

          await FirebaseFirestore.instance
              .collection('deliveries')
              .doc(req['id'])
              .update({
            'status': 'accepted',
            'driverId': uid,
            'driverName': driverName,
            'acceptedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            Navigator.pop(context);
            // After accepting, we navigate to the tracking map
            Navigator.pushNamed(context, '/active-delivery',
                arguments: req['id']);
          }
        },
      ),
    ).then((_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isOverlayShown = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    _deliverySubscription?.cancel();
    _posTimer?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  //  BOTTOM NAVIGATION BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomNav(bool dark) {
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF111D35) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentIndex = i;
                });
              }
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: dark ? const Color(0xFF111D35) : Colors.white,
          selectedItemColor:
              dark ? AppColors.brandYellow : AppColors.primaryBlue,
          unselectedItemColor: dark ? Colors.grey[600] : Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentRole?.toLowerCase() == 'mechanic'
                  ? Icons.shopping_bag
                  : currentRole?.toLowerCase() == 'delivery'
                      ? Icons.assignment
                      : Icons.garage_rounded),
              label: currentRole?.toLowerCase() == 'mechanic'
                  ? 'Shop'
                  : currentRole?.toLowerCase() == 'delivery'
                      ? 'Jobs'
                      : 'Garage',
            ),
            BottomNavigationBarItem(
              icon: Icon(currentRole?.toLowerCase() == 'delivery'
                  ? Icons.account_balance_wallet
                  : Icons.payments_rounded),
              label: currentRole?.toLowerCase() == 'delivery'
                  ? 'Earnings'
                  : 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  ROLE ROUTER
  // ─────────────────────────────────────────────
  Widget _buildDashboardContent(String role, bool dark) {
    switch (role.toLowerCase()) {
      case 'mechanic':
        return _mechanicDashboard(role, dark);
      case 'tow':
        return _towDashboard(role, dark);
      case 'seller':
        return _sellerDashboard(role, dark);
      case 'delivery':
        return _deliveryDashboard(role, dark);
      default:
        return _userDashboard(role, dark);
    }
  }

  // ═════════════════════════════════════════════
  //  1. USER DASHBOARD (default)
  // ═════════════════════════════════════════════
  Widget _userDashboard(String role, bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: role,
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('vehicleType', 'My Vehicle'),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 16),

          // Real Map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                  ),
                ),
                child: _userLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          OsmMapWidget(
                            center: _userLocation!,
                            markers: [
                              Marker(
                                point: _userLocation!,
                                width: 30,
                                height: 30,
                                child: const Icon(Icons.my_location,
                                    color: AppColors.primaryBlue),
                              ),
                            ],
                          ),
                          // 🧪 Debug: Spawn Mock Mechanic
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () =>
                                  TestService.instance.spawnMockMechanic(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.redAccent.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bug_report,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Report Breakdown header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Breakdown',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '24/7 ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          dark ? AppColors.brandYellow : AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action cards grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.smart_toy,
                        subtitle: 'VIRTUAL AID',
                        title: 'AI Assistant',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              Navigator.pushNamed(context, '/ai-chat');
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.build,
                        subtitle: 'ON-SITE REPAIR',
                        title: 'Mechanic',
                        color: const Color(0xFFE65100),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(
                                  context, '/searching-mechanics');
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.store_rounded,
                        subtitle: 'SHOP TOOLS',
                        title: 'Browse Shop',
                        color: const Color(0xFF1B5E20),
                        onTap: () {
                          // Redirect to searching for mechanics who have products/shops
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(
                                  context, '/searching-mechanics');
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.phone_in_talk,
                        subtitle: 'LIVE SUPPORT',
                        title: 'Call Support',
                        color: const Color(0xFF1A2940),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(context, '/call-support');
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildOngoingRequestsSection(dark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  2. MECHANIC DASHBOARD
  // ═════════════════════════════════════════════
  Widget _mechanicDashboard(String role, bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: role,
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('workshop', 'My Workshop'),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _paymentHistoryStream,
                builder: (context, snapshot) {
                  final payments = snapshot.data ?? [];
                  final totalEarnings = payments.fold<num>(
                      0, (sum, p) => sum + (p['amount'] ?? 0));
                  final jobCount = payments.length;

                  return Row(
                    children: [
                      StatCard(
                        icon: Icons.work_history,
                        value: jobCount.toString(),
                        label: "Total Jobs",
                        accentColor: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        icon: Icons.star,
                        value: '4.8', // Mock for now
                        label: 'Rating',
                        accentColor: AppColors.brandYellow,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        icon: Icons.account_balance_wallet,
                        value: 'Rs. ${totalEarnings ~/ 1000}K',
                        label: 'Earnings',
                        accentColor: Colors.green,
                      ),
                    ],
                  );
                }),
          ),
          const SizedBox(height: 24),

          // Availability toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isMechanicActive
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isMechanicActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isMechanicActive ? 'You are Online' : 'You are Offline',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isMechanicActive,
                    onChanged: _toggleMechanicActive,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section header
          _sectionTitle('Incoming Requests', dark),
          const SizedBox(height: 12),

          // Real-time Incoming Requests List
          _mechanicRequestsSection(dark),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.check_circle,
                    subtitle: 'MANAGE',
                    title: 'Accept Jobs',
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Accepting jobs coming soon...")),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.history,
                    subtitle: 'VIEW',
                    title: 'Job History',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.pushNamed(context, '/job-history');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _partsInTransitCard(
              FirebaseAuth.instance.currentUser?.uid ?? '', dark),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  2b. MECHANIC — Parts In Transit card (delivery)
  // ═════════════════════════════════════════════
  Widget _partsInTransitCard(String uid, bool dark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deliveries')
          .where('mechanicId', isEqualTo: uid)
          .where('status', whereIn: ['accepted', 'en_route'])
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Parts In Transit', dark),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: dark ? Colors.grey[800]! : Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delivery_dining,
                            color: Colors.blue, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d['itemName'] ?? 'Part',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Driver: ${d['driverName'] ?? 'Assigned'}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    dark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (d['status'] as String? ?? 'en_route').toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ═════════════════════════════════════════════
  Widget _towDashboard(String role, bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: role,
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('truckModel', 'My Truck'),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.local_shipping,
                  value: '3',
                  label: 'Active Tows',
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.route,
                  value: '48 km',
                  label: 'Distance',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 18K',
                  label: 'Earnings',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Map placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      size: 40,
                      color: dark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live Tracking Map',
                      style: TextStyle(
                        color: dark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pending requests
          _sectionTitle('Pending Tow Requests', dark),
          const SizedBox(height: 12),

          _jobRequestCard(
            'Vehicle Breakdown',
            'Colombo 07 • Sedan • 4.2 km',
            Icons.car_crash,
            Colors.red,
            dark,
          ),
          _jobRequestCard(
            'Accident Recovery',
            'Nugegoda • SUV • 6.1 km',
            Icons.warning_amber,
            Colors.orange,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.play_circle_fill,
                    subtitle: 'NAVIGATE',
                    title: 'Start Tow',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) Navigator.pushNamed(context, '/location');
                      });
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.support_agent,
                    subtitle: 'HELP',
                    title: 'Support',
                    color: const Color(0xFF1A2940),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          Navigator.pushNamed(context, '/call-support');
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  4. SELLER DASHBOARD
  // ═════════════════════════════════════════════
  Widget _sellerDashboard(String role, bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: role,
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('shopName', 'My Shop'),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.shopping_bag,
                  value: '12',
                  label: "Today's Orders",
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.inventory_2,
                  value: '156',
                  label: 'Products',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.trending_up,
                  value: 'LKR 45K',
                  label: 'Revenue',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent orders
          _sectionTitle('Recent Orders', dark),
          const SizedBox(height: 12),

          _orderCard(
            'Brake Pads Set',
            'Order #1042 • Colombo 05',
            'Processing',
            Colors.orange,
            dark,
          ),
          _orderCard(
            'Engine Oil 5W-30',
            'Order #1041 • Dehiwala',
            'Shipped',
            Colors.blue,
            dark,
          ),
          _orderCard(
            'Air Filter – Toyota',
            'Order #1040 • Kandy',
            'Delivered',
            Colors.green,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.add_box,
                        subtitle: 'INVENTORY',
                        title: 'Add Product',
                        color: const Color(0xFF2E7D32),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Add product coming soon...")),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.list_alt,
                        subtitle: 'MANAGE',
                        title: 'View Orders',
                        color: const Color(0xFF1565C0),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              Navigator.pushNamed(context, '/order-tracking');
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.analytics,
                        subtitle: 'INSIGHTS',
                        title: 'Analytics',
                        color: const Color(0xFF6A1B9A),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Analytics coming soon...")),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.chat_bubble,
                        subtitle: 'CUSTOMERS',
                        title: 'Messages',
                        color: const Color(0xFFE65100),
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted)
                              Navigator.pushNamed(context, '/mechanic-chat');
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  5. DELIVERY DASHBOARD (replaces old driver stub)
  // ═════════════════════════════════════════════
  Widget _deliveryDashboard(String role, bool dark) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: 'Delivery',
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('plate', _rd('vehicleType', 'My Vehicle')),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _paymentHistoryStream,
              builder: (context, snapshot) {
                final done = snapshot.data ?? [];
                final totalEarnings = done.fold<num>(
                    0, (s, d) => s + (d['earnings'] ?? 0));
                return Row(
                  children: [
                    StatCard(
                      icon: Icons.delivery_dining,
                      value: done.length.toString(),
                      label: 'Deliveries',
                      accentColor: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.route,
                      value: '${(done.length * 4.2).toStringAsFixed(0)} km',
                      label: 'Distance',
                      accentColor: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    StatCard(
                      icon: Icons.account_balance_wallet,
                      value: 'Rs. ${totalEarnings ~/ 1000}K',
                      label: 'Earnings',
                      accentColor: Colors.green,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Online / Offline toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isDeliveryActive
                      ? Colors.green.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color:
                          _isDeliveryActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isDeliveryActive
                          ? 'You are Online'
                          : 'You are Offline',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Switch(
                    value: _isDeliveryActive,
                    onChanged: (val) => _toggleDeliveryActive(val, uid),
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Live Location Map ──
          _sectionTitle('Your Location', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: _userLocation != null
                    ? OsmMapWidget(
                        center: _userLocation!,
                        zoom: 14,
                        showLocateButton: false,
                        markers: [
                          Marker(
                            point: _userLocation!,
                            width: 48,
                            height: 48,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.delivery_dining,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.darkSurface
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_off,
                                  size: 36,
                                  color: dark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Location unavailable',
                                style: TextStyle(
                                    color: dark
                                        ? Colors.grey[500]
                                        : Colors.grey[500],
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active delivery (accepted / en_route)
          _sectionTitle('Active Delivery', dark),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _ongoingRequestsStream,
            builder: (context, snapshot) {
              final active = snapshot.data ?? [];
              if (active.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'No active delivery.',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 14),
                  ),
                );
              }
              final d = active.first;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [
                              const Color(0xFF1E3A5F),
                              const Color(0xFF15294A)
                            ]
                          : [
                              const Color(0xFFE3F2FD),
                              const Color(0xFFBBDEFB)
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: dark
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.blue.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.local_shipping,
                                color: Colors.blue, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['itemName'] ?? 'Item',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        dark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                Text(
                                  'To: ${d['dropAddress'] ?? 'Destination'}',
                                  style: TextStyle(
                                    color: dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              d['status'] == 'en_route' ? 0.65 : 0.3,
                          minHeight: 6,
                          backgroundColor: dark
                              ? Colors.grey[800]
                              : Colors.blue.withValues(alpha: 0.1),
                          valueColor: const AlwaysStoppedAnimation(
                              Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(
                            context, '/active-delivery',
                            arguments: d['id']),
                        icon: const Icon(Icons.map, size: 16),
                        label: const Text('View Active Route'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Available jobs (pending from seller / mechanic)
          _sectionTitle('Available Jobs', dark),
          const SizedBox(height: 12),
          _availableDeliveryJobsSection(dark),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.history,
                    subtitle: 'VIEW',
                    title: 'Delivery History',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.pushNamed(
                        context, '/delivery-history'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.support_agent,
                    subtitle: 'HELP',
                    title: 'Call Support',
                    color: const Color(0xFF1A2940),
                    onTap: () =>
                        Navigator.pushNamed(context, '/call-support'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Toggle delivery online/offline
  Future<void> _toggleDeliveryActive(bool value, String uid) async {
    setState(() => _isDeliveryActive = value);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'roles.delivery.isActive': value});
    } catch (e) {
      if (mounted) setState(() => _isDeliveryActive = !value);
    }
  }

  Widget _driverDashboard(String role, bool dark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardHeader(
            userName: isLoading ? 'Loading...' : userName,
            role: role,
            photoUrl: userPhotoUrl,
            vehicleInfo: _rd('deliveryArea', 'My Area'),
            availableRoles: allRoles.keys.toList(),
            onSwitchRole: _switchRole,
          ),
          const SizedBox(height: 20),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                StatCard(
                  icon: Icons.delivery_dining,
                  value: '8',
                  label: 'Deliveries',
                  accentColor: Colors.orange,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.route,
                  value: '32 km',
                  label: 'Distance',
                  accentColor: Colors.blue,
                ),
                const SizedBox(width: 12),
                StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 8K',
                  label: 'Earnings',
                  accentColor: Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Current delivery
          _sectionTitle('Active Delivery', dark),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: dark
                      ? [const Color(0xFF1E3A5F), const Color(0xFF15294A)]
                      : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brake Pads – Toyota',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Deliver to: Colombo 07 • 3.2 km',
                              style: TextStyle(
                                color:
                                    dark ? Colors.grey[400] : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      minHeight: 6,
                      backgroundColor: dark
                          ? Colors.grey[800]
                          : Colors.blue.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation(Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En Route • ETA 12 min',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[300],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pending deliveries
          _sectionTitle('Pending Deliveries', dark),
          const SizedBox(height: 12),

          _jobRequestCard(
            'Engine Oil 5W-30',
            'Dehiwala • 5.4 km away',
            Icons.oil_barrel,
            Colors.amber,
            dark,
          ),
          _jobRequestCard(
            'Air Filter Set',
            'Mount Lavinia • 8.1 km away',
            Icons.filter_alt,
            Colors.teal,
            dark,
          ),
          const SizedBox(height: 20),

          // Quick actions
          _sectionTitle('Quick Actions', dark),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.check_circle,
                    subtitle: 'ACCEPT',
                    title: 'New Delivery',
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          Navigator.pushNamed(context, '/order-tracking');
                      });
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: QuickActionCard(
                    icon: Icons.map,
                    subtitle: 'NAVIGATE',
                    title: 'View Route',
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) Navigator.pushNamed(context, '/location');
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  SHARED HELPER WIDGETS
  // ═════════════════════════════════════════════

  /// Service pill chip (User dashboard)
  Widget _servicePill(IconData icon, String label, bool dark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: dark ? Colors.grey[400] : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section title with left padding
  Widget _sectionTitle(String text, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: dark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  /// Job / request card (Mechanic, Tow, Driver dashboards)
  Widget _jobRequestCard(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
    bool dark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: dark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  /// Order card (Seller dashboard)
  Widget _orderCard(
    String title,
    String subtitle,
    String status,
    Color statusColor,
    bool dark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: dark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.shopping_bag, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingRequestsSection(bool dark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _ongoingRequestsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sync,
                      color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Ongoing Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...requests.map((req) => _ongoingRequestCard(req, dark)),
            ],
          ),
        );
      },
    );
  }

  Widget _ongoingRequestCard(Map<String, dynamic> req, bool dark) {
    final status = req['status'] ?? 'pending';
    final name = req['mechanicName'] ?? 'Searching...';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(Icons.engineering, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: status == 'pending'
                        ? Colors.orange
                        : status == 'accepted'
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
                if (status == 'accepted' || status == 'arriving')
                  Text(
                    'Live tracking available',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (status == 'pending') {
                  Navigator.pushNamed(context, '/searching-mechanics',
                      arguments: {'serviceType': req['serviceType']});
                } else if (status == 'accepted' ||
                    status == 'arriving' ||
                    status == 'arrived') {
                  final route = (status == 'accepted')
                      ? '/mechanic-accepted'
                      : '/order-tracking';
                  Navigator.pushNamed(context, route, arguments: req['id']);
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _mechanicRequestsSection(bool dark) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _mechanicIncomingRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'No new requests.',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          );
        }

        return Column(
          children:
              requests.map((req) => _realJobRequestCard(req, dark)).toList(),
        );
      },
    );
  }

  Widget _realJobRequestCard(Map<String, dynamic> req, bool dark) {
    final title = req['serviceType'] ?? 'Engine Repair';
    final user = req['userName'] ?? 'Client';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.build_circle, color: Colors.orange, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: dark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          '$user • Nearby Now',
          style: TextStyle(
            fontSize: 13,
            color: dark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        trailing: ElevatedButton(
          onPressed: () => _showNewRequestDialog(req),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandYellow,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('View',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }
}
