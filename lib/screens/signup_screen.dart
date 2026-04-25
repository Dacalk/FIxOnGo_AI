import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/social_button.dart';
import '../components/phone_input.dart';
import '../components/form_input.dart';
import '../components/form_dropdown.dart';
import '../components/role_dropdown.dart';

import '../services/google_auth_service.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ================= VARIABLES =================
  String? _selectedRole;

  String fullName = '';
  String vehicleType = '';
  String plate = '';
  String color = '';
  String emergency = '';

  String expertise = '';
  String nic = '';
  String workshop = '';
  String experience = '';

  String truckModel = '';
  String towingCapacity = '';

  String deliveryArea = '';

  String shopName = '';
  String category = '';
  String address = '';

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _phoneError;

  final GoogleAuthService _googleAuth = GoogleAuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showEmailSignup = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize role from arguments only once
    if (_selectedRole == null) {
      final String? initialRole =
          ModalRoute.of(context)?.settings.arguments as String?;
      if (initialRole != null) {
        _selectedRole = initialRole;
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  //  GOOGLE SIGNUP
  Future<void> _handleGoogleSignup() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role first")),
      );
      return;
    }
    setState(() => _isGoogleLoading = true);
    try {
      final user = await _googleAuth.signInWithGoogle();
      if (user != null) {
        // We stay on this screen to fill the rest of the form
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // 🔵 OTP FLOW
  void _onGetOtp() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role first")),
      );
      return;
    }
    final error = PhoneInput.validateSriLankanPhone(_phoneController.text);
    setState(() => _phoneError = error);

    if (error == null) {
      await Navigator.pushNamed(
        context,
        '/verification',
        arguments: {
          'phone': _phoneController.text,
          'role': _selectedRole,
        },
      );
      // After returning from verification, refresh UI to show "Authenticated as..."
      if (mounted) setState(() {});
    }
  }

  // ================= SAVE FUNCTION =================
  Future<void> _saveUser(String role) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? _emailController.text.trim(),
      'phone': user.phoneNumber ?? '',
      'photoUrl': user.photoURL ?? '',
      'displayName': user.displayName ?? fullName,
      'roles': {
        role.toLowerCase(): {
          'fullName': fullName,
          'vehicleType': vehicleType,
          'plate': plate,
          'color': color,
          'emergency': emergency,
          'expertise': expertise,
          'nic': nic,
          'workshop': workshop,
          'experience': experience,
          'truckModel': truckModel,
          'towingCapacity': towingCapacity,
          'deliveryArea': deliveryArea,
          'shopName': shopName,
          'category': category,
          'address': address,
          'updatedAt': Timestamp.now(),
        }
      }
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final role = _selectedRole ?? 'User';

    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;

    final backBtnBg = dark ? AppColors.darkSurface : Colors.blue[50]!;
    final backBtnIcon = dark ? Colors.white : Colors.black;
    final appBarTitleColor = dark ? Colors.white : AppColors.primaryBlue;

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CREATE ACCOUNT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: appBarTitleColor,
            letterSpacing: 1,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: backBtnBg,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: backBtnIcon,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CHOOSE YOUR ROLE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            RoleDropdown(
              initialValue: _selectedRole,
              onChanged: (v) {
                setState(() {
                  _selectedRole = v;
                });
              },
            ),
            const SizedBox(height: 28),
            if (currentUser == null) ...[
              Text(
                'STEP 1: AUTHENTICATION',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showEmailSignup
                        ? "Sign up with Email"
                        : "Sign up with Mobile",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor.withValues(alpha: 0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showEmailSignup = !_showEmailSignup),
                    child: Text(
                      _showEmailSignup ? "Use Phone" : "Use Email",
                      style: const TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_showEmailSignup) ...[
                FormInput(
                  label: 'Email Address',
                  hintText: 'example@mail.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                FormInput(
                  label: 'Password',
                  hintText: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isLoading ? "Creating..." : "Continue to Profile",
                  isLoading: _isLoading,
                  onPressed: () async {
                    if (_selectedRole == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please select a role first")),
                      );
                      return;
                    }
                    try {
                      setState(() => _isLoading = true);
                      await FirebaseAuth.instance
                          .createUserWithEmailAndPassword(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                      );
                      if (mounted) setState(() {});
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Auth Error: ${e.message}")),
                      );
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                ),
              ] else ...[
                PhoneInput(
                  controller: _phoneController,
                  errorText: _phoneError,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: "Get OTP",
                  onPressed: _onGetOtp,
                  icon: Icons.arrow_forward,
                ),
              ],
              const SizedBox(height: 30),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("Or continue with"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: SocialButton(
                      label: "Google",
                      imagePath: "lib/assets/google.png",
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignup,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: SocialButton(
                      label: "Apple",
                      imagePath: "lib/assets/apple.png",
                      onPressed: () {
                        print("Apple login not implemented yet");
                      },
                    ),
                  ),
                ],
              ),
              if (_isGoogleLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ] else ...[
              Text(
                'STEP 2: PROFILE DETAILS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Authenticated as ${currentUser.email ?? currentUser.phoneNumber ?? 'User'}",
                        style: TextStyle(fontSize: 14, color: titleColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        setState(() {});
                      },
                      child:
                          const Text("Change", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              ..._buildFormFields(role),
              const SizedBox(height: 32),
              PrimaryButton(
                label: _isLoading ? 'Saving...' : 'Finish Registration',
                isLoading: _isLoading,
                onPressed: () async {
                  if (_selectedRole == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please select a role first")),
                    );
                    return;
                  }
                  try {
                    setState(() => _isLoading = true);
                    await _saveUser(role);

                    if (mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(role: role),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}")),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                borderRadius: 15,
              ),
            ],
            const SizedBox(height: 32),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                        color: dark ? Colors.white70 : Colors.black54),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ================= FORM FIELDS =================

  List<Widget> _defaultUserFields() {
    return [
      FormInput(
          label: 'Full Name',
          hintText: 'Anna De Parie',
          onChanged: (v) => fullName = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Vehicle Type',
        hintText: 'Select Vehicle Type',
        items: [
          'Car',
          'SUV',
          'Van',
          'Motorcycle',
          'Three-Wheeler',
          'Bus',
          'Truck'
        ],
        onChanged: (v) => vehicleType = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Vehicle Plate Number',
          hintText: 'PH-1234',
          onChanged: (v) => plate = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Vehicle Color',
          hintText: 'White',
          onChanged: (v) => color = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Emergency Contact',
          hintText: '7XXXXXXXX',
          onChanged: (v) => emergency = v),
    ];
  }

  List<Widget> _mechanicFields() {
    return [
      FormInput(
          label: 'Full Name', hintText: 'Anna', onChanged: (v) => fullName = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Expertise',
        hintText: 'Select Skill',
        items: ['Engine', 'Electrical', 'Brake', 'Transmission', 'Paint', 'AC'],
        onChanged: (v) => expertise = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'NIC / ID Number',
          hintText: '123456789V',
          onChanged: (v) => nic = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Workshop Name',
          hintText: 'ABC Garage',
          onChanged: (v) => workshop = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Years of Experience',
          hintText: '5',
          onChanged: (v) => experience = v),
    ];
  }



  List<Widget> _towFields() {
    return [
      FormInput(
          label: 'Truck Model',
          hintText: 'Isuzu Elf',
          onChanged: (v) => truckModel = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Towing Capacity (Tons)',
          hintText: '3.5',
          onChanged: (v) => towingCapacity = v),
    ];
  }


  List<Widget> _sellerFields() {
    return [
      FormInput(
          label: 'Shop Name',
          hintText: 'FixMate Auto Parts',
          onChanged: (v) => shopName = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Business Category',
        hintText: 'Select Category',
        items: [
          'Spare Parts',
          'Accessories',
          'Tires & Wheels',
          'Tools',
          'Lubricants'
        ],
        onChanged: (v) => category = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Shop Address',
          hintText: '123 Main St, Colombo',
          onChanged: (v) => address = v),
    ];
  }

  List<Widget> _buildFormFields(String role) {
    switch (role) {
      case 'Mechanic':
        return _mechanicFields();
      case 'Tow Trucker':
        return _towFields();
      case 'Seller':
        return _sellerFields();
      default:
        return _defaultUserFields();
    }
  }
}
