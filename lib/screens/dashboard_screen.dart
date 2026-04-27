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
import 'job_history_screen.dart';
import 'payment_history_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
import 'seller_inbox_screen.dart';

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
  StreamSubscription? _towRequestSubscription; // Separate sub for towing
  Timer? _posTimer;
  String? _lastDialogRequestId;
  bool _isNavigating = false;
  bool _isOverlayShown = false;
  bool _isInitialized = false;

  // Real-time data streams
  Stream<List<Map<String, dynamic>>>? _ongoingRequestsStream;
  Stream<List<Map<String, dynamic>>>? _paymentHistoryStream;
  bool _isMechanicActive = true;
  Stream<List<Map<String, dynamic>>>? _mechanicIncomingRequestsStream;
  Stream<List<Map<String, dynamic>>>? _towIncomingRequestsStream;
  Stream<List<Map<String, dynamic>>>? _towPaymentHistoryStream;

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
        final towRole = rolesMap['tow'] ??
            rolesMap['mechanic']; // Fix: use 'tow' instead of 'tow owner'

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
              final fbName =
                  (data?['displayName']?.toString().isNotEmpty == true)
                      ? data!['displayName'].toString()
                      : null;

              if (currentRole?.toLowerCase() == 'seller' &&
                  rd['shopName']?.toString().isNotEmpty == true) {
                userName = rd['shopName'];
              } else {
                userName = rd['fullName']?.toString().isNotEmpty == true
                    ? rd['fullName']
                    : fbName ?? user.displayName ?? 'User';
              }
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

            // 🚛 START TOWING SERVICES IF ROLE EXISTS
            final isTowOwner = rolesMap.containsKey('tow');
            if (isTowOwner) {
              _initTowServices(user.uid);
              _initTowDataStreams(user.uid);
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
                role.toLowerCase() == 'mechanic' ||
                        role.toLowerCase() == 'seller'
                    ? MechanicShopScreen(isEmbedded: true, role: role)
                    : const JobHistoryScreen(
                        isEmbedded: true, isMechanicView: false),
                PaymentHistoryScreen(
                  isEmbedded: true,
                  isProviderView: role.toLowerCase() == 'mechanic' ||
                      role.toLowerCase() == 'tow',
                  filterType: role.toLowerCase() == 'tow'
                      ? 'towing'
                      : (role.toLowerCase() == 'mechanic' ? 'mechanic' : null),
                ),
                ProfileScreen(
                  isEmbedded: true,
                  role: role,
                  userData: {
                    'fullName': userName,
                    'email': userEmail,
                    'photoUrl': userPhotoUrl,
                  },
                  onSwitchTab: (tabIndex) {
                    if (mounted) {
                      setState(() => _currentIndex = tabIndex);
                    }
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
      if (mounted) {
        setState(() => _userLocation = loc);
      }
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

  void _initTowServices(String uid) {
    // 1. Update location periodically for Tow role
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final loc = await LocationService.instance.getCurrentLatLng();
      if (mounted) {
        setState(() => _userLocation = loc);
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'roles.tow.location': {'lat': loc.latitude, 'lng': loc.longitude},
        'roles.tow.lastSeen': FieldValue.serverTimestamp(),
      });
    });

    // 2. Listen for Towing Requests (Broadcasts: mechanicId == null)
    _towRequestSubscription?.cancel();
    _towRequestSubscription = FirebaseFirestore.instance
        .collection('requests')
        .where('type', isEqualTo: 'towing')
        .where('status', isEqualTo: 'pending')
        .where('mechanicId', isNull: true)
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

  void _initTowDataStreams(String uid) {
    // Incoming Broadcast Requests for Tow: status == pending, type == towing, mechanicId == null
    _towIncomingRequestsStream = FirebaseFirestore.instance
        .collection('requests')
        .where('type', isEqualTo: 'towing')
        .where('status', isEqualTo: 'pending')
        .where('mechanicId', isNull: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

    // Payment History for Tow
    _towPaymentHistoryStream = FirebaseFirestore.instance
        .collection('payments')
        .where('mechanicId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
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
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;

          // If it's a broadcast request, claim it!
          await FirebaseFirestore.instance
              .collection('requests')
              .doc(req['id'])
              .update({
            'mechanicId': user.uid,
            'mechanicName': userName,
            'status': 'accepted',
            'acceptedAt': FieldValue.serverTimestamp(),
          });
          _requestSubscription?.cancel();
          _towRequestSubscription?.cancel(); // Cancel both on accept
          _lastDialogRequestId = null;

          if (mounted) {
            Navigator.pop(context);
          }
          // Navigate to tracking screen
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                if (_isNavigating) return;
                _isNavigating = true;
                final targetRoute = req['type'] == 'towing'
                    ? '/tow-nav-to-user'
                    : '/mechanic-nav-to-user';
                Navigator.pushNamed(context, targetRoute, arguments: req['id']);
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

  @override
  void dispose() {
    _requestSubscription?.cancel();
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
              icon: Icon(currentRole?.toLowerCase() == 'mechanic' ||
                      currentRole?.toLowerCase() == 'seller'
                  ? Icons.shopping_bag
                  : Icons.history_rounded),
              label: currentRole?.toLowerCase() == 'mechanic' ||
                      currentRole?.toLowerCase() == 'seller'
                  ? 'Shop'
                  : 'Activities',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_rounded),
              label: 'Payments',
            ),
            const BottomNavigationBarItem(
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
      case 'tow trucker':
        return _towDashboard(role, dark);
      case 'seller':
        return _sellerDashboard(role, dark);
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: QuickActionCard(
                        icon: Icons.local_shipping_rounded,
                        subtitle: 'EMERGENCY AID',
                        title: 'Towing & Roadside',
                        color: AppColors.emergencyRed,
                        onTap: () {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              Navigator.pushNamed(context, '/towing-booking');
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Spacer(),
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
          _buildLiveTrackingMap(dark, _towIncomingRequestsStream,
              Icons.local_shipping, Icons.car_crash, Colors.red),
          const SizedBox(height: 24),
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
          _buildLiveTrackingMap(dark, _mechanicIncomingRequestsStream,
              Icons.engineering, Icons.build_circle, Colors.orange),
          const SizedBox(height: 24),

          // Section header
          _sectionTitle('Incoming Requests', dark),

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
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════
  //  3. TOW DASHBOARD
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _towPaymentHistoryStream,
                builder: (context, snapshot) {
                  final payments = snapshot.data ?? [];
                  final totalEarnings = payments.fold<num>(
                      0, (sum, p) => sum + (p['amount'] ?? 0));
                  final jobCount = payments.length;

                  return Row(
                    children: [
                      StatCard(
                        icon: Icons.local_shipping,
                        value: jobCount.toString(),
                        label: 'Total Tows',
                        accentColor: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      StatCard(
                        icon: Icons.route,
                        value: '---',
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
                }),
          ),
          const SizedBox(height: 24),

          // Live Tracking Map
          _buildLiveTrackingMap(dark, _towIncomingRequestsStream,
              Icons.local_shipping, Icons.car_crash, Colors.red),
          const SizedBox(height: 24),

          // Pending requests
          _sectionTitle('Pending Tow Requests', dark),
          const SizedBox(height: 12),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _towIncomingRequestsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  child: Text(
                    "No pending tow requests nearby.",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                );
              }
              final requests = snapshot.data!;
              return Column(
                children: requests.map((req) {
                  final vehicle =
                      req['vehicleDetails'] as Map<String, dynamic>?;
                  final makeModel = vehicle?['makeModel'] ?? 'Unknown Vehicle';
                  final distance = req['estimatedDistance'] ?? '?.?';

                  return _jobRequestCard(
                    req['serviceType'] ?? 'Towing Request',
                    '$makeModel • $distance km away',
                    Icons.car_crash,
                    Colors.red,
                    dark,
                  );
                }).toList(),
              );
            },
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
                    title: 'My Tow Truck',
                    color: const Color(0xFFE65100),
                    onTap: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted)
                          Navigator.pushNamed(context, '/tow-vehicle');
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
    final user = FirebaseAuth.instance.currentUser;
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('sellerId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Expanded(
                      child: StatCard(
                        icon: Icons.shopping_bag,
                        value: count.toString(),
                        label: "All Orders",
                        accentColor: Colors.orange,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user?.uid)
                      .collection('products')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.docs.length ?? 0;
                    return Expanded(
                      child: StatCard(
                        icon: Icons.inventory_2,
                        value: count.toString(),
                        label: 'Products',
                        accentColor: Colors.blue,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('payments')
                      .where('sellerId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final double revenue = snapshot.data?.docs.fold(
                            0.0, (sum, doc) => sum! + (doc['amount'] ?? 0.0)) ??
                        0.0;
                    return Expanded(
                      child: StatCard(
                        icon: Icons.trending_up,
                        value: 'Rs. ${(revenue / 1000).toStringAsFixed(1)}K',
                        label: 'Revenue',
                        accentColor: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Recent orders
          _sectionTitle('Recent Orders', dark),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('sellerId', isEqualTo: user?.uid)
                .orderBy('createdAt', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                      child: Text("No orders yet",
                          style: TextStyle(color: Colors.grey[500]))),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _orderCard(
                    data['productName'] ?? 'Product',
                    'Order #${doc.id.substring(0, 5).toUpperCase()} • ${data['customerName'] ?? 'Customer'}',
                    data['status'] ?? 'Pending',
                    data['status'] == 'Delivered' ? Colors.green : Colors.blue,
                    dark,
                  );
                }).toList(),
              );
            },
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
                          Navigator.pushNamed(context, '/add-product');
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
                          Navigator.pushNamed(context, '/job-history');
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
                        icon: Icons.account_balance_wallet,
                        subtitle: 'EARNINGS',
                        title: 'My Wallet',
                        color: const Color(0xFF6A1B9A),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WalletScreen(role: role),
                            ),
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SellerInboxScreen(),
                            ),
                          );
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

  // ─── LIVE TRACKING MAP WIDGET ──────────────────────────────────
  Widget _buildLiveTrackingMap(
      bool dark,
      Stream<List<Map<String, dynamic>>>? stream,
      IconData providerIcon,
      IconData jobIcon,
      Color jobColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: dark ? AppColors.darkSurface : Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: dark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
          boxShadow: [
            if (!dark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _userLocation == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snapshot) {
                    final pendingRequests = snapshot.data ?? [];
                    final markers = pendingRequests
                        .map((req) {
                          final loc =
                              req['userLocation'] as Map<String, dynamic>?;
                          if (loc == null) return null;
                          return Marker(
                            point: LatLng(loc['lat'], loc['lng']),
                            width: 35,
                            height: 35,
                            child: Container(
                              decoration: BoxDecoration(
                                color: jobColor.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: jobColor, width: 2),
                              ),
                              child: Icon(jobIcon, color: jobColor, size: 18),
                            ),
                          );
                        })
                        .whereType<Marker>()
                        .toList();

                    return OsmMapWidget(
                      center: _userLocation!,
                      zoom: 13,
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 45,
                          height: 45,
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primaryBlue.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.primaryBlue, width: 2),
                            ),
                            child: Icon(providerIcon,
                                color: AppColors.primaryBlue, size: 24),
                          ),
                        ),
                        ...markers,
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}
