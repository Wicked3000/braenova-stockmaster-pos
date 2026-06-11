import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingProduct; // Null if adding, populated if editing

  const AddProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _qtyController;
  late TextEditingController _thresholdController;
  late TextEditingController _barcodeController;
  
  String? _selectedCategory;
  List<dynamic> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final item = widget.existingProduct;
    _nameController = TextEditingController(text: item?['item_name'] ?? '');
    _priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    _costController = TextEditingController(text: item?['cost']?.toString() ?? '0.0');
    _qtyController = TextEditingController(text: item?['stock_qty']?.toString() ?? '0');
    _thresholdController = TextEditingController(text: item?['low_stock_threshold']?.toString() ?? '5');
    _barcodeController = TextEditingController(text: item?['barcode'] ?? '');
    
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.getCategories();
      if (response.data['success']) {
        setState(() {
          _categories = response.data['data'];
          if (widget.existingProduct != null) {
            _selectedCategory = widget.existingProduct!['category_id']?.toString();
          }
        });
      }
    } catch (e) {
      // Ignore or show error
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final client = ref.read(apiClientProvider);
    final productData = {
      'item_name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0.0,
      'cost': double.tryParse(_costController.text) ?? 0.0,
      'stock_qty': int.tryParse(_qtyController.text) ?? 0,
      'low_stock_threshold': int.tryParse(_thresholdController.text) ?? 5,
      'barcode': _barcodeController.text,
      'category_id': _selectedCategory,
    };

    try {
      if (widget.existingProduct == null) {
        // Add
        final res = await client.addProduct(productData);
        if (res.data['success'] && mounted) {
          Navigator.of(context).pop(true); // Return true to signal refresh
        }
      } else {
        // Edit
        final res = await client.updateProduct(widget.existingProduct!['id'], productData);
        if (res.data['success'] && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _qtyController.dispose();
    _thresholdController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProduct == null ? 'Add Product' : 'Edit Product'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                    validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Selling Price (K)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _costController,
                          decoration: const InputDecoration(labelText: 'Cost Price (K)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          decoration: const InputDecoration(labelText: 'Stock Qty', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _thresholdController,
                          decoration: const InputDecoration(labelText: 'Low Stock Threshold', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    value: _selectedCategory,
                    items: _categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['name'] ?? c['id'].toString(), // Adjust based on API structure
                        child: Text(c['name'] ?? c['id'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Barcode', 
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: () {
                          // Barcode scanning logic goes here
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(widget.existingProduct == null ? 'Add Product' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
