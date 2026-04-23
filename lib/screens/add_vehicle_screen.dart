import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme_provider.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  bool _isLoading = false;
  Vehicle? _editingVehicle;

  final VehicleService _vehicleService = VehicleService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Vehicle && _editingVehicle == null) {
      _editingVehicle = args;
      _makeController.text = _editingVehicle!.make;
      _modelController.text = _editingVehicle!.model;
      _yearController.text = _editingVehicle!.year;
      _plateController.text = _editingVehicle!.plateNumber;
    }
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final vehicle = Vehicle(
        id: _editingVehicle?.id ?? '',
        userId: user.uid,
        make: _makeController.text.trim(),
        model: _modelController.text.trim(),
        year: _yearController.text.trim(),
        plateNumber: _plateController.text.trim().toUpperCase(),
        isPrimary: _editingVehicle?.isPrimary ?? false,
      );

      if (_editingVehicle != null) {
        await _vehicleService.updateVehicle(user.uid, vehicle);
      } else {
        await _vehicleService.addVehicle(user.uid, vehicle);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingVehicle != null ? 'Vehicle updated successfully!' : 'Vehicle added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FA);
    final titleColor = dark ? Colors.white : Colors.black;
    final isEdit = _editingVehicle != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF1E2836) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? 'Edit Vehicle' : 'Add New Vehicle',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: dark ? AppColors.darkSurface : Colors.grey[100],
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 18,
                color: dark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Vehicle Information', titleColor),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _makeController,
                label: 'Make',
                hint: 'e.g. Toyota',
                icon: Icons.directions_car,
                dark: dark,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _modelController,
                label: 'Model',
                hint: 'e.g. Camry',
                icon: Icons.model_training,
                dark: dark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _yearController,
                      label: 'Year',
                      hint: 'e.g. 2022',
                      keyboardType: TextInputType.number,
                      dark: dark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _plateController,
                      label: 'Plate Number',
                      hint: 'e.g. ABC-1234',
                      dark: dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveVehicle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark ? AppColors.brandYellow : AppColors.primaryBlue,
                    foregroundColor: dark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : Text(
                          isEdit ? 'Update Vehicle' : 'Save Vehicle',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color.withValues(alpha: 0.7),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    required bool dark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.grey[400] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: dark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: dark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: dark ? AppColors.brandYellow : AppColors.primaryBlue) : null,
            filled: true,
            fillColor: dark ? const Color(0xFF1E2836) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: dark ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: dark ? BorderSide.none : BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: dark ? AppColors.brandYellow : AppColors.primaryBlue),
            ),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
        ),
      ],
    );
  }
}
