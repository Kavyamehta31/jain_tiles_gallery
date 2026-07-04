import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_title.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController otherBrandController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController piecesController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedBrand;
  String? selectedSize;
  String? selectedVariety;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  bool get isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      final p = widget.product!;
      nameController.text = p.name;

      if (AppConstants.brands.contains(p.brand)) {
        selectedBrand = p.brand;
      } else {
        selectedBrand = 'Other';
        otherBrandController.text = p.brand;
      }

      selectedSize = p.size;
      selectedVariety = p.variety;
      quantityController.text = p.boxesInStock.toString();
      piecesController.text = p.piecesPerBox.toString();
      priceController.text = p.sellingPricePerBox.toString();
      descriptionController.text = p.description;

      _selectedImages = p.imagePaths.map((path) => File(path)).toList();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    otherBrandController.dispose();
    quantityController.dispose();
    piecesController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to pick images: $e")),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final finalBrand = selectedBrand == 'Other'
          ? otherBrandController.text.trim()
          : selectedBrand!;

      final Product productData = Product(
        id: widget.product?.id,
        name: nameController.text.trim(),
        brand: finalBrand,
        size: selectedSize!,
        variety: selectedVariety!,
        boxesInStock: int.parse(quantityController.text),
        piecesPerBox: int.parse(piecesController.text),
        sellingPricePerBox: double.parse(priceController.text),
        description: descriptionController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      );

      if (isEditMode) {
        await _productService.updateProduct(productData);
      } else {
        await _productService.addProduct(productData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditMode
                ? "Product updated successfully"
                : "Product added successfully",
          ),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error saving product: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save product: $e"),
            backgroundColor: AppColors.error,
          ),
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
  Widget build(BuildContext context) {
    // Determine dynamic variety list based on selected size
    final List<String> availableVarieties = AppConstants.getVarieties(selectedSize);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Tile Product" : "Add Tile Product"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(title: "Product Images"),
              ImagePickerCard(
                images: _selectedImages,
                onPickImages: _pickImages,
                onRemoveImage: _removeImage,
              ),
              const SizedBox(height: 16),

              const SectionTitle(title: "General Information"),
              CustomTextField(
                controller: nameController,
                label: "Tile Name",
                hint: "e.g., Onyx Gold Polished",
                validator: (val) =>
                    val == null || val.trim().isEmpty ? "Name is required" : null,
              ),

              CustomDropdown<String>(
                label: "Brand",
                value: selectedBrand,
                items: AppConstants.brands,
                onChanged: (val) {
                  setState(() {
                    selectedBrand = val;
                  });
                },
                validator: (val) => val == null ? "Brand is required" : null,
              ),

              if (selectedBrand == 'Other')
                CustomTextField(
                  controller: otherBrandController,
                  label: "Custom Brand Name",
                  hint: "Enter custom brand",
                  validator: (val) {
                    if (selectedBrand == 'Other' &&
                        (val == null || val.trim().isEmpty)) {
                      return "Custom brand name is required";
                    }
                    return null;
                  },
                ),

              CustomDropdown<String>(
                label: "Size",
                value: selectedSize,
                items: AppConstants.sizes,
                onChanged: (val) {
                  setState(() {
                    selectedSize = val;
                    // Reset variety if it's not valid for the new size
                    selectedVariety = null;
                  });
                },
                validator: (val) => val == null ? "Size is required" : null,
              ),

              CustomDropdown<String>(
                label: "Variety",
                value: selectedVariety,
                items: availableVarieties,
                onChanged: (val) {
                  setState(() {
                    selectedVariety = val;
                  });
                },
                validator: (val) => val == null ? "Variety is required" : null,
              ),

              const SectionTitle(title: "Inventory & Pricing"),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: quantityController,
                      label: "Boxes in Stock",
                      hint: "0",
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Required";
                        }
                        if (int.tryParse(val) == null || int.parse(val) < 0) {
                          return "Invalid count";
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: piecesController,
                      label: "Pieces per Box",
                      hint: "4",
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Required";
                        }
                        if (int.tryParse(val) == null || int.parse(val) <= 0) {
                          return "Invalid pieces";
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: priceController,
                label: "Selling Price per Box (₹)",
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return "Price is required";
                  }
                  final parsed = double.tryParse(val);
                  if (parsed == null || parsed <= 0) {
                    return "Must be greater than 0";
                  }
                  return null;
                },
              ),

              const SectionTitle(title: "Additional Info"),
              CustomTextField(
                controller: descriptionController,
                label: "Description (Optional)",
                hint: "Enter color notes, design patterns, etc.",
                maxLines: 3,
              ),

              const SizedBox(height: 24),
              PrimaryButton(
                text: isEditMode ? "Update Product" : "Save Product",
                isLoading: _isLoading,
                onPressed: _saveProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
