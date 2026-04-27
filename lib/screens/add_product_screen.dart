import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme_provider.dart';
import '../components/primary_button.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  String _category = 'Tools';
  String? _productId;
  bool _isLoading = false;
  bool _isInStock = true;
  String? _existingImageUrl;
  Uint8List? _imageBytes;

  Uint8List? _base64ToBytes(String str) {
    if (str.isEmpty) return null;
    try {
      final b64 = str.contains(',') ? str.split(',')[1] : str;
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _productId == null) {
      _productId = args['id'];
      _nameController.text = args['name'] ?? '';
      _priceController.text = (args['price'] ?? '').toString();
      _descController.text = args['description'] ?? '';
      _category = args['category'] ?? 'Tools';
      _stockController.text = (args['stockCount'] ?? 1).toString();
      _isInStock = args['inStock'] ?? true;
      _existingImageUrl = args['imageUrl'];
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String imageUrlToSave = _existingImageUrl ?? '';
    if (_imageBytes != null) {
      imageUrlToSave = 'data:image/png;base64,${base64Encode(_imageBytes!)}';
    }

    // Use local timestamp to avoid FieldValue.serverTimestamp() inside Map
    // which can cause permission issues on Flutter Web.
    final now = Timestamp.fromDate(DateTime.now());

    final data = <String, dynamic>{
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'description': _descController.text.trim(),
      'category': _category,
      'stockCount': int.tryParse(_stockController.text) ?? 1,
      'inStock': _isInStock,
      'imageUrl': imageUrlToSave,
      'updatedAt': now,
    };

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('products');

      if (_productId == null) {
        // New product — include createdAt
        await ref.add({...data, 'createdAt': now});
      } else {
        await ref.doc(_productId!).update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_productId == null ? 'Add New Product' : 'Edit Product'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: dark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldTitle('Product Name', dark),
              TextFormField(
                controller: _nameController,
                decoration: _inputDeco('e.g. 12-Piece Wrench Set', dark),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldTitle('Price (Rs.)', dark),
                        TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('0.00', dark),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldTitle('Stock Count', dark),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('1', dark),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _fieldTitle('Category', dark),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkSurface : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    dropdownColor: dark ? AppColors.darkSurface : Colors.white,
                    items: ['Tools', 'Parts', 'Accessories', 'Oils']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _category = v!);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _fieldTitle('Description', dark),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration:
                    _inputDeco('Enter details about the product...', dark),
              ),
              const SizedBox(height: 20),

              // Stock Status Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _fieldTitle('Availability Status', dark),
                  Switch(
                    value: _isInStock,
                    onChanged: (v) => setState(() => _isInStock = v),
                    activeColor: Colors.green,
                  ),
                ],
              ),
              Text(
                _isInStock ? 'In Stock' : 'Out of Stock',
                style: TextStyle(
                  fontSize: 12,
                  color: _isInStock ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Image Picker
              _fieldTitle('Product Photo', dark),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: dark ? Colors.grey[800]! : Colors.grey[300]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _base64ToBytes(_existingImageUrl!) != null
                                  ? Image.memory(
                                      _base64ToBytes(_existingImageUrl!)!,
                                      fit: BoxFit.cover)
                                  : Image.network(_existingImageUrl!,
                                      fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.grey[400]),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap to upload product photo',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                label: _isLoading ? 'Saving...' : 'Save Product',
                onPressed: _isLoading ? () {} : _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldTitle(String title, bool dark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: dark ? Colors.grey[400] : Colors.grey[700],
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, bool dark) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: dark ? AppColors.darkSurface : Colors.grey[100],
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
