import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/form_input.dart';
import '../components/form_dropdown.dart';

import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ================= VARIABLES =================
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= SAVE FUNCTION =================
  Future<void> _saveUser(String role) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception("Email and Password are required");
      }
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      user = cred.user;
    }

    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      // 🔹 COMMON DATA
      'uid': user.uid,
      'email': user.email ?? _emailController.text.trim(),
      'phone': user.phoneNumber ?? '',

      //  ROLE BASED DATA
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
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }
    }, SetOptions(merge: true)); //  IMPORTANT
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'User';

    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.grey[400]! : Colors.grey[600]!;

    final backBtnBg = dark ? AppColors.darkSurface : Colors.blue[50]!;
    final backBtnIcon = dark ? Colors.white : Colors.black;
    final appBarTitleColor = dark ? Colors.white : AppColors.primaryBlue;

    String appBarTitle;
    String description;

    switch (role) {
      case 'Mechanic':
        appBarTitle = 'MECHANIC ACCOUNT';
        description =
            'Help drivers in need and grow your business with our breakdown network.';
        break;
      case 'Tow':
        appBarTitle = 'TOWING ACCOUNT';
        description = 'Provide towing services for broken down vehicles.';
        break;
      case 'Driver':
        appBarTitle = 'DRIVER ACCOUNT';
        description = 'Deliver parts and essentials to drivers in need.';
        break;
      case 'Seller':
        appBarTitle = 'SELLER ACCOUNT';
        description = 'Sell vehicle parts and accessories.';
        break;
      default:
        appBarTitle = 'CREATE ACCOUNT';
        description = 'We need this info to help identify you faster.';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          appBarTitle,
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
              'CREATE ACCOUNT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            if (FirebaseAuth.instance.currentUser == null) ...[
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
            ],
            ..._buildFormFields(role),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Verify & Continue',
              onPressed: () async {
                try {
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
                }
              },
              borderRadius: 15,
            ),
            const SizedBox(height: 32),
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
          label: 'Full Name', hintText: 'Anna', onChanged: (v) => fullName = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Tow Truck Model',
          hintText: 'Hino',
          onChanged: (v) => truckModel = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Towing Capacity',
        hintText: 'Select Capacity',
        items: ['1-2', '2-5', '5-10', '10-20', '20+'],
        onChanged: (v) => towingCapacity = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Vehicle Plate Number',
          hintText: 'ABC-1234',
          onChanged: (v) => plate = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Workshop Name',
          hintText: 'Garage',
          onChanged: (v) => workshop = v),
    ];
  }

  List<Widget> _driverFields() {
    return [
      FormInput(
          label: 'Full Name', hintText: 'Anna', onChanged: (v) => fullName = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Vehicle Type',
        hintText: 'Select Vehicle',
        items: ['Motorcycle', 'Three-Wheeler', 'Car', 'Van'],
        onChanged: (v) => vehicleType = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Vehicle Plate Number',
          hintText: 'ABC-1234',
          onChanged: (v) => plate = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'NIC / ID', hintText: '123456789V', onChanged: (v) => nic = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Delivery Area',
        hintText: 'Select Area',
        items: ['Colombo', 'Gampaha', 'Kandy', 'Galle', 'Matara'],
        onChanged: (v) => deliveryArea = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Emergency Contact',
          hintText: '7XXXXXXXX',
          onChanged: (v) => emergency = v),
    ];
  }

  List<Widget> _sellerFields() {
    return [
      FormInput(
          label: 'Full Name', hintText: 'Anna', onChanged: (v) => fullName = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Shop Name',
          hintText: 'My Shop',
          onChanged: (v) => shopName = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'NIC / ID', hintText: '123456789V', onChanged: (v) => nic = v),
      const SizedBox(height: 20),
      FormDropdown(
        label: 'Business Category',
        hintText: 'Select Category',
        items: ['Spare Parts', 'Tires', 'Engine', 'Electrical', 'Accessories'],
        onChanged: (v) => category = v ?? '',
      ),
      const SizedBox(height: 20),
      FormInput(
          label: 'Business Address',
          hintText: 'Colombo',
          onChanged: (v) => address = v),
      const SizedBox(height: 20),
      FormInput(
          label: 'Emergency Contact',
          hintText: '7XXXXXXXX',
          onChanged: (v) => emergency = v),
    ];
  }

  List<Widget> _buildFormFields(String role) {
    switch (role) {
      case 'Mechanic':
        return _mechanicFields();
      case 'Tow':
        return _towFields();
      case 'Driver':
        return _driverFields();
      case 'Seller':
        return _sellerFields();
      default:
        return _defaultUserFields();
    }
  }
}
