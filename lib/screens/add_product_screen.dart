import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });
    final user = FirebaseAuth.instance.currentUser;

    final data = {
      'name': _nameController.text.trim(),
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'description': _descController.text.trim(),
      'category': _category,
      'stockCount': int.tryParse(_stockController.text) ?? 1,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('products');

      if (_productId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await ref.add(data);
      } else {
        await ref.doc(_productId).update(data);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (!mounted) return;
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
