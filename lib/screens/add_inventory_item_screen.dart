import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../theme_provider.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({super.key});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isLoading = false;
  InventoryItem? _editingItem;
  
  XFile? _pickedImage;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();

  final InventoryService _inventoryService = InventoryService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is InventoryItem && _editingItem == null) {
      _editingItem = args;
      _nameController.text = _editingItem!.name;
      _quantityController.text = _editingItem!.quantity.toString();
      _priceController.text = _editingItem!.price.toString();
      _categoryController.text = _editingItem!.category ?? '';
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = image;
        _webImage = bytes;
      });
    }
  }

  Future<void> _saveItem() async {
    print("AddInventory Debug: _saveItem called");
    if (!_formKey.currentState!.validate()) {
      print("AddInventory Debug: Validation failed");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("AddInventory Debug: No user found");
        throw Exception("User not logged in");
      }
      
      print("AddInventory Debug: User is ${user.uid}");

      String? imageUrl = _editingItem?.imageUrl;
      
      // Upload new image if picked
      if (_webImage != null) {
        print("AddInventory Debug: Image picked, starting upload...");
        final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await _inventoryService.uploadItemImage(user.uid, fileName, _webImage!);
        print("AddInventory Debug: Upload finished, URL: $imageUrl");
      } else {
        print("AddInventory Debug: No new image picked");
      }

      final item = InventoryItem(
        id: _editingItem?.id ?? '',
        userId: user.uid,
        name: _nameController.text.trim(),
        quantity: int.parse(_quantityController.text.trim()),
        price: double.parse(_priceController.text.trim()),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        imageUrl: imageUrl,
      );

      if (_editingItem != null) {
        print("AddInventory Debug: Updating existing item...");
        await _inventoryService.updateItem(user.uid, item);
      } else {
        print("AddInventory Debug: Adding new item...");
        await _inventoryService.addItem(user.uid, item);
      }
      
      print("AddInventory Debug: SUCCESS");
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_editingItem != null ? 'Item updated successfully!' : 'Item added successfully!')),
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
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : const Color(0xFFF8F9FA);
    final titleColor = dark ? Colors.white : Colors.black;
    final isEdit = _editingItem != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF1E2836) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? 'Edit Product' : 'Add New Product',
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
              // ── Image Picker ──
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF1E2836) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                      ),
                      image: (_webImage != null)
                          ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                          : (_editingItem?.imageUrl != null)
                              ? DecorationImage(image: NetworkImage(_editingItem!.imageUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_webImage == null && _editingItem?.imageUrl == null)
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: dark ? AppColors.brandYellow : AppColors.primaryBlue),
                              const SizedBox(height: 8),
                              const Text('Add Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('Product Information', titleColor),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g. Engine Oil 5W-30',
                icon: Icons.inventory_2,
                dark: dark,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _quantityController,
                      label: 'Quantity',
                      hint: 'e.g. 10',
                      keyboardType: TextInputType.number,
                      dark: dark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price (Rs.)',
                      hint: 'e.g. 2500',
                      keyboardType: TextInputType.number,
                      dark: dark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _categoryController,
                label: 'Category (Optional)',
                hint: 'e.g. Lubricants',
                icon: Icons.category,
                dark: dark,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveItem,
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
                          isEdit ? 'Update Product' : 'Save Product',
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
