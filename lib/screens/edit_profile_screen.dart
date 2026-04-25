import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../theme_provider.dart';

/// Edit Profile Screen — lets users update their full registration form details.
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> roleData;
  final String role;
  final String initialPhotoUrl;
  final String email;
  final String phone;

  const EditProfileScreen({
    super.key,
    required this.roleData,
    required this.role,
    required this.initialPhotoUrl,
    required this.email,
    required this.phone,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Common
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  // Role Specific - using a map to handle dynamic fields
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _dropdownValues = {};

  XFile? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.roleData['fullName'] ?? '');
    _phoneController = TextEditingController(text: widget.phone);
    
    _initRoleControllers();
  }

  void _initRoleControllers() {
    final data = widget.roleData;
    
    // Define fields for each role to initialize controllers/values
    if (widget.role.toLowerCase() == 'mechanic') {
      _controllers['nic'] = TextEditingController(text: data['nic'] ?? '');
      _controllers['workshop'] = TextEditingController(text: data['workshop'] ?? '');
      _controllers['experience'] = TextEditingController(text: data['experience'] ?? '');
      _dropdownValues['expertise'] = data['expertise'] ?? '';
    } else if (widget.role.toLowerCase() == 'user') {
      _controllers['plate'] = TextEditingController(text: data['plate'] ?? '');
      _controllers['color'] = TextEditingController(text: data['color'] ?? '');
      _controllers['emergency'] = TextEditingController(text: data['emergency'] ?? '');
      _dropdownValues['vehicleType'] = data['vehicleType'] ?? '';
    } else if (widget.role.toLowerCase() == 'tow') {
      _controllers['truckModel'] = TextEditingController(text: data['truckModel'] ?? '');
      _controllers['plate'] = TextEditingController(text: data['plate'] ?? '');
      _controllers['workshop'] = TextEditingController(text: data['workshop'] ?? '');
      _dropdownValues['towingCapacity'] = data['towingCapacity'] ?? '';
    } else if (widget.role.toLowerCase() == 'driver') {
      _controllers['plate'] = TextEditingController(text: data['plate'] ?? '');
      _controllers['nic'] = TextEditingController(text: data['nic'] ?? '');
      _controllers['emergency'] = TextEditingController(text: data['emergency'] ?? '');
      _dropdownValues['vehicleType'] = data['vehicleType'] ?? '';
      _dropdownValues['deliveryArea'] = data['deliveryArea'] ?? '';
    } else if (widget.role.toLowerCase() == 'seller') {
      _controllers['shopName'] = TextEditingController(text: data['shopName'] ?? '');
      _controllers['nic'] = TextEditingController(text: data['nic'] ?? '');
      _controllers['address'] = TextEditingController(text: data['address'] ?? '');
      _controllers['emergency'] = TextEditingController(text: data['emergency'] ?? '');
      _dropdownValues['category'] = data['category'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _pickedImage = image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet(bool dark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF1E2836) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Update Profile Photo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              _sheetOption(
                ctx,
                dark,
                icon: Icons.camera_alt_outlined,
                label: 'Take a Photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 12),
              _sheetOption(
                ctx,
                dark,
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetOption(
    BuildContext ctx,
    bool dark, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF253447) : const Color(0xFFF4F8FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: dark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Save Logic ───────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final roleKey = widget.role.toLowerCase();
      
      // Build role-specific updates
      final Map<String, dynamic> roleUpdates = {
        'fullName': name,
        'updatedAt': Timestamp.now(),
      };
      
      // Add dynamic fields
      _controllers.forEach((key, ctrl) {
        roleUpdates[key] = ctrl.text.trim();
      });
      _dropdownValues.forEach((key, val) {
        roleUpdates[key] = val;
      });

      // Build main update map
      final Map<String, dynamic> mainUpdates = {
        'phone': phone,
        'roles.$roleKey': roleUpdates,
      };

      // Handle Image
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        final base64 = _bytesToBase64(bytes);
        final mimeType = _pickedImage!.mimeType ?? 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,$base64';
        mainUpdates['photoUrl'] = dataUrl;
        // NOTE: We do NOT call user.updatePhotoURL(dataUrl) here 
        // because Firebase Auth has a short limit on URL length,
        // and base64 strings will trigger "Photo URL too long" error.
      }

      try {
        // Try to clear the long photoURL to fix the broken profile state
        if (user.photoURL != null && user.photoURL!.length > 1000) {
          await user.updatePhotoURL(null);
        }
        await user.updateDisplayName(name);
      } catch (authError) {
        print("Auth Profile Update Error (Ignored): $authError");
        // Proceeding anyway because the main data is saved in Firestore
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(mainUpdates, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _bytesToBase64(List<int> bytes) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result.write(chars[(b0 >> 2) & 0x3F]);
      result.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      result.write(i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=');
      result.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return result.toString();
  }

  Uint8List _base64ToBytes(String base64Str) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final cleaned = base64Str.replaceAll(RegExp(r'\s'), '');
    final result = <int>[];
    for (var i = 0; i < cleaned.length; i += 4) {
      final c0 = chars.indexOf(cleaned[i]);
      final c1 = chars.indexOf(cleaned[i + 1]);
      final c2 = cleaned[i + 2] == '=' ? 0 : chars.indexOf(cleaned[i + 2]);
      final c3 = cleaned[i + 3] == '=' ? 0 : chars.indexOf(cleaned[i + 3]);
      result.add(((c0 << 2) | (c1 >> 4)) & 0xFF);
      if (cleaned[i + 2] != '=') result.add(((c1 << 4) | (c2 >> 2)) & 0xFF);
      if (cleaned[i + 3] != '=') result.add(((c2 << 6) | c3) & 0xFF);
    }
    return Uint8List.fromList(result);
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final topBgColor = dark ? const Color(0xFF1E2836) : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = dark ? const Color(0xFF1E2836) : const Color(0xFFF4F8FA);
    final borderColor = dark ? const Color(0xFF2A3A50) : const Color(0xFFE0E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: topBgColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Edit ${widget.role} Profile',
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
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                )
              : TextButton(
                  onPressed: _save,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? AppColors.brandYellow : AppColors.primaryBlue,
                    ),
                  ),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Avatar Section ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: topBgColor,
              padding: const EdgeInsets.only(bottom: 32, top: 12),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourceSheet(dark),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            shape: BoxShape.circle,
                            border: Border.all(color: dark ? const Color(0xFF2A3A50) : const Color(0xFFD4E3FB), width: 4),
                          ),
                          child: ClipOval(child: _buildAvatarContent(dark)),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle, border: Border.all(color: topBgColor, width: 3)),
                            child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Tap photo to change', style: TextStyle(fontSize: 12, color: subColor)),
                ],
              ),
            ),

            // ── Form Fields ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Basic Information', dark),
                  const SizedBox(height: 12),
                  _buildFormContainer(dark, borderColor, cardBg, [
                    _buildField(label: 'Full Name', controller: _nameController, icon: Icons.person_outline, dark: dark, titleColor: titleColor, subColor: subColor),
                    _buildField(label: 'Phone Number', controller: _phoneController, icon: Icons.phone_outlined, dark: dark, titleColor: titleColor, subColor: subColor, keyboardType: TextInputType.phone, showDivider: false),
                  ]),

                  const SizedBox(height: 24),
                  _sectionLabel('${widget.role} Details', dark),
                  const SizedBox(height: 12),
                  _buildFormContainer(dark, borderColor, cardBg, _buildRoleFields(dark, titleColor, subColor)),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormContainer(bool dark, Color borderColor, Color cardBg, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(children: children),
    );
  }

  List<Widget> _buildRoleFields(bool dark, Color titleColor, Color subColor) {
    final role = widget.role.toLowerCase();
    
    if (role == 'mechanic') {
      return [
        _buildDropdown(label: 'Expertise', field: 'expertise', items: ['Engine', 'Electrical', 'Brake', 'Transmission', 'Paint', 'AC'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'NIC / ID Number', controller: _controllers['nic']!, icon: Icons.badge_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Workshop Name', controller: _controllers['workshop']!, icon: Icons.storefront_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Years of Experience', controller: _controllers['experience']!, icon: Icons.timeline_outlined, dark: dark, titleColor: titleColor, subColor: subColor, keyboardType: TextInputType.number, showDivider: false),
      ];
    } else if (role == 'user') {
      return [
        _buildDropdown(label: 'Vehicle Type', field: 'vehicleType', items: ['Car', 'SUV', 'Van', 'Motorcycle', 'Three-Wheeler', 'Bus', 'Truck'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Vehicle Plate Number', controller: _controllers['plate']!, icon: Icons.numbers_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Vehicle Color', controller: _controllers['color']!, icon: Icons.palette_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Emergency Contact', controller: _controllers['emergency']!, icon: Icons.emergency_outlined, dark: dark, titleColor: titleColor, subColor: subColor, keyboardType: TextInputType.phone, showDivider: false),
      ];
    } else if (role == 'tow') {
      return [
        _buildField(label: 'Tow Truck Model', controller: _controllers['truckModel']!, icon: Icons.local_shipping_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildDropdown(label: 'Towing Capacity', field: 'towingCapacity', items: ['1-2', '2-5', '5-10', '10-20', '20+'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Vehicle Plate Number', controller: _controllers['plate']!, icon: Icons.numbers_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Workshop Name', controller: _controllers['workshop']!, icon: Icons.storefront_outlined, dark: dark, titleColor: titleColor, subColor: subColor, showDivider: false),
      ];
    } else if (role == 'driver') {
      return [
        _buildDropdown(label: 'Vehicle Type', field: 'vehicleType', items: ['Motorcycle', 'Three-Wheeler', 'Car', 'Van'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Vehicle Plate Number', controller: _controllers['plate']!, icon: Icons.numbers_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'NIC / ID', controller: _controllers['nic']!, icon: Icons.badge_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildDropdown(label: 'Delivery Area', field: 'deliveryArea', items: ['Colombo', 'Gampaha', 'Kandy', 'Galle', 'Matara'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Emergency Contact', controller: _controllers['emergency']!, icon: Icons.emergency_outlined, dark: dark, titleColor: titleColor, subColor: subColor, keyboardType: TextInputType.phone, showDivider: false),
      ];
    } else if (role == 'seller') {
      return [
        _buildField(label: 'Shop Name', controller: _controllers['shopName']!, icon: Icons.store_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'NIC / ID', controller: _controllers['nic']!, icon: Icons.badge_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildDropdown(label: 'Business Category', field: 'category', items: ['Spare Parts', 'Tires', 'Engine', 'Electrical', 'Accessories'], dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Business Address', controller: _controllers['address']!, icon: Icons.location_on_outlined, dark: dark, titleColor: titleColor, subColor: subColor),
        _buildField(label: 'Emergency Contact', controller: _controllers['emergency']!, icon: Icons.emergency_outlined, dark: dark, titleColor: titleColor, subColor: subColor, keyboardType: TextInputType.phone, showDivider: false),
      ];
    }
    
    return [Center(child: Text('No additional fields for this role.'))];
  }

  Widget _buildAvatarContent(bool dark) {
    if (_pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedImage!.readAsBytes(),
          builder: (ctx, snap) {
            if (snap.hasData) return Image.memory(snap.data!, fit: BoxFit.cover, width: 110, height: 110);
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: 110, height: 110);
      }
    }

    final url = widget.initialPhotoUrl;
    if (url.isNotEmpty && url.startsWith('data:')) {
      try {
        final comma = url.indexOf(',');
        final bytes = _base64ToBytes(url.substring(comma + 1));
        return Image.memory(bytes, fit: BoxFit.cover, width: 110, height: 110, errorBuilder: (_, __, ___) => _initialsWidget());
      } catch (_) { return _initialsWidget(); }
    } else if (url.isNotEmpty) {
      return Image.network(url, fit: BoxFit.cover, width: 110, height: 110, errorBuilder: (_, __, ___) => _initialsWidget());
    }

    return _initialsWidget();
  }

  Widget _initialsWidget() {
    return Center(
      child: Text(
        _getInitials(_nameController.text.isNotEmpty ? _nameController.text : widget.roleData['fullName'] ?? 'U'),
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
      ),
    );
  }

  Widget _sectionLabel(String text, bool dark) {
    return Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: dark ? Colors.grey[400] : Colors.grey[500], letterSpacing: 0.5));
  }

  Widget _buildField({required String label, required TextEditingController controller, required IconData icon, required bool dark, required Color titleColor, required Color subColor, TextInputType keyboardType = TextInputType.text, bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: dark ? const Color(0xFF253447) : Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: dark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                child: Icon(icon, size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500)),
                    TextField(
                      controller: controller, keyboardType: keyboardType,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
      ],
    );
  }

  Widget _buildDropdown({required String label, required String field, required List<String> items, required bool dark, required Color titleColor, required Color subColor, bool showDivider = true}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: dark ? const Color(0xFF253447) : Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.list_alt_outlined, size: 20, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 11, color: subColor, fontWeight: FontWeight.w500)),
                    DropdownButton<String>(
                      value: _dropdownValues[field]?.isNotEmpty == true ? _dropdownValues[field] : null,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.keyboard_arrow_down, size: 18, color: subColor),
                      items: items.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor)))).toList(),
                      onChanged: (v) => setState(() => _dropdownValues[field] = v ?? ''),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Divider(height: 1, color: dark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
      ],
    );
  }
}
