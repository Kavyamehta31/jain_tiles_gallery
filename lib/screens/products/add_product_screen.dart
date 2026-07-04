import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final ProductService _productService = ProductService();

  final TextEditingController nameController = TextEditingController();
  String? selectedBrand;
  String? selectedSize;

  final TextEditingController otherBrandController = TextEditingController();
  final TextEditingController otherSizeController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController piecesController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    brandController.dispose();
    sizeController.dispose();
    quantityController.dispose();
    piecesController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (nameController.text.trim().isEmpty ||
        brandController.text.trim().isEmpty ||
        sizeController.text.trim().isEmpty ||
        quantityController.text.trim().isEmpty ||
        piecesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    final product = Product(
      name: nameController.text.trim(),
      brand: brandController.text.trim(),
      size: sizeController.text.trim(),
      quantity: int.parse(quantityController.text),
      piecesPerBox: int.parse(piecesController.text),
      description: descriptionController.text.trim(),
    );

    await _productService.addProduct(product);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Product added successfully")));

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // Image picker will be added next.
                },
                icon: const Icon(Icons.photo_library),
                label: const Text("Add Images"),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Product Name",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: "Brand",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: sizeController,
                decoration: const InputDecoration(
                  labelText: "Size",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Boxes in Stock",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: piecesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Pieces per Box",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text(
                    "Save Product",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
