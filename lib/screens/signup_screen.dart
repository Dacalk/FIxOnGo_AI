import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../components/form_input.dart';
import '../components/form_dropdown.dart';

/// Signup screen that adapts its form fields based on the selected role.
///
/// Roles & their fields (from design screenshots):
///  • User    → Full Name, Vehicle Type, Plate Number, Vehicle Color, Emergency Contact
///  • Mechanic → Full Name, Expertise, NIC/ID, Workshop Name, Years of Experience
///  • Tow     → Full Name, Truck Model, Towing Capacity, Plate Number, Workshop Name
///  • Seller  → Full Name, Shop Name, NIC/ID, Business Category, Address, Emergency Contact
///  • Driver  → Full Name, Vehicle Type, Plate Number, NIC/ID, Delivery Area, Emergency Contact
class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the role passed from the previous screen
    final role =
        ModalRoute.of(context)?.settings.arguments as String? ?? 'User';

    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subtitleColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final backBtnBg = dark ? AppColors.darkSurface : Colors.blue[50]!;
    final backBtnIcon = dark ? Colors.white : Colors.black;
    final appBarTitleColor =
        dark ? Colors.white : AppColors.primaryBlue;

    // Determine the app bar title based on role
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
        description =
            'Deliver parts and essentials to drivers in need, right where they are.';
        break;
      case 'Seller':
        appBarTitle = 'SELLER ACCOUNT';
        description =
            'Sell vehicle parts and accessories to drivers who need them most.';
        break;
      default:
        appBarTitle = 'CREATE ACCOUNT';
        description =
            'We need this info to help our response team identify you faster during an emergency.';
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
            // Header
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

            // ── Role-dependent form fields ──
            ..._buildFormFields(role),

            const SizedBox(height: 32),

            // Submit button
            PrimaryButton(
              label: 'Verify & Continue',
              onPressed: () {
                // TODO: Handle form submission
              },
              borderRadius: 15,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Returns the form fields based on the selected role.
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

  // ─────────────────────────────────────────────
  //  DEFAULT USER FORM
  // ─────────────────────────────────────────────
  List<Widget> _defaultUserFields() {
    return const [
      FormInput(
        label: 'Full Name',
        hintText: 'Anna De Parie',
      ),
      SizedBox(height: 20),
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
          'Truck',
          'Other',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Vehicle Plate Number',
        hintText: 'PH - 1234',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Vehicle Color',
        hintText: 'e.g. White',
        helperText: 'This helps us spot your car on the road.',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Emergency Contact',
        hintText: '7X XXX XXXX',
        keyboardType: TextInputType.phone,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  MECHANIC FORM
  // ─────────────────────────────────────────────
  List<Widget> _mechanicFields() {
    return const [
      FormInput(
        label: 'Full Name',
        hintText: 'Anna De Parie',
      ),
      SizedBox(height: 20),
      FormDropdown(
        label: 'Expertise',
        hintText: 'Select Primary Skill',
        items: [
          'Engine Repair',
          'Electrical Systems',
          'Brake & Suspension',
          'Transmission',
          'Body & Paint',
          'AC & Cooling',
          'General Maintenance',
          'Other',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'NIC / ID Number',
        hintText: '254552 451552V',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Workshop Name',
        hintText: 'Enter business name',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Years of Experience',
        hintText: 'e.g. 5',
        keyboardType: TextInputType.number,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  TOW TRUCK DRIVER FORM
  // ─────────────────────────────────────────────
  List<Widget> _towFields() {
    return const [
      FormInput(
        label: 'Full Name',
        hintText: 'Anna De Parie',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Tow Truck Model',
        hintText: 'e.g. Hino 300 series',
      ),
      SizedBox(height: 20),
      FormDropdown(
        label: 'Towing Capacity (Tons)',
        hintText: 'Select Capacity',
        items: [
          '1 - 2 Tons',
          '2 - 5 Tons',
          '5 - 10 Tons',
          '10 - 20 Tons',
          '20+ Tons',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Vehicle Plate Number',
        hintText: 'ABC -1234',
        helperText: 'This helps us identify your truck on the road.',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Workshop Name',
        hintText: 'Enter Your Business',
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  DELIVERY DRIVER FORM
  // ─────────────────────────────────────────────
  List<Widget> _driverFields() {
    return const [
      FormInput(
        label: 'Full Name',
        hintText: 'Anna De Parie',
      ),
      SizedBox(height: 20),
      FormDropdown(
        label: 'Vehicle Type',
        hintText: 'Select Vehicle Type',
        items: [
          'Motorcycle',
          'Three-Wheeler',
          'Car',
          'Van',
          'Truck',
          'Other',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Vehicle Plate Number',
        hintText: 'ABC -1234',
        helperText: 'This helps us identify your vehicle on the road.',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'NIC / ID Number',
        hintText: '254552 451552V',
      ),
      SizedBox(height: 20),
      FormDropdown(
        label: 'Delivery Area',
        hintText: 'Select Primary Zone',
        items: [
          'Colombo',
          'Gampaha',
          'Kalutara',
          'Kandy',
          'Galle',
          'Matara',
          'Kurunegala',
          'Island-wide',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Emergency Contact',
        hintText: '7X XXX XXXX',
        keyboardType: TextInputType.phone,
      ),
    ];
  }

  // ─────────────────────────────────────────────
  //  SELLER FORM
  // ─────────────────────────────────────────────
  List<Widget> _sellerFields() {
    return const [
      FormInput(
        label: 'Full Name',
        hintText: 'Anna De Parie',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Shop / Business Name',
        hintText: 'Enter your business name',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'NIC / ID Number',
        hintText: '254552 451552V',
      ),
      SizedBox(height: 20),
      FormDropdown(
        label: 'Business Category',
        hintText: 'Select Category',
        items: [
          'Spare Parts',
          'Tires & Wheels',
          'Engine & Mechanical',
          'Electrical & Battery',
          'Oil & Lubricants',
          'Accessories',
          'Tools & Equipment',
          'Other',
        ],
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Business Address',
        hintText: 'Enter your shop address',
      ),
      SizedBox(height: 20),
      FormInput(
        label: 'Emergency Contact',
        hintText: '7X XXX XXXX',
        keyboardType: TextInputType.phone,
      ),
    ];
  }
}
