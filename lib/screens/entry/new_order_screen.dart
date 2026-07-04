import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_title.dart';

class OrderRowItem {
  Product? product;
  final TextEditingController priceController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  double lineTotal = 0.0;
  final VoidCallback onChanged;

  OrderRowItem({required this.onChanged}) {
    priceController.addListener(_recalc);
    quantityController.addListener(_recalc);
  }

  void _recalc() {
    final price = double.tryParse(priceController.text) ?? 0.0;
    final qty = int.tryParse(quantityController.text) ?? 0;
    lineTotal = price * qty;
    onChanged();
  }

  void dispose() {
    priceController.dispose();
    quantityController.dispose();
  }
}

class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key});

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _remarksController = TextEditingController();
  final List<OrderRowItem> _rows = [];
  List<Product> _products = [];
  
  bool _isLoading = true;
  bool _isSaving = false;
  
  int _totalBoxes = 0;
  double _grandTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _productService.getProducts();
      setState(() {
        _products = products;
        _isLoading = false;
        // Start with one empty row
        _addRow();
      });
    } catch (e) {
      debugPrint("Error loading products: $e");
      setState(() => _isLoading = false);
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(
        OrderRowItem(
          onChanged: _recalculateTotals,
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("An order must contain at least one item row."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() {
      final row = _rows.removeAt(index);
      row.dispose();
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    int boxes = 0;
    double amount = 0.0;
    for (final r in _rows) {
      boxes += int.tryParse(r.quantityController.text) ?? 0;
      amount += r.lineTotal;
    }
    setState(() {
      _totalBoxes = boxes;
      _grandTotal = amount;
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verify row products selection
    for (int i = 0; i < _rows.length; i++) {
      if (_rows[i].product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please select a product for row #${i + 1}"),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // Check for duplicate products in order rows
    final selectedProductIds = <int>{};
    for (final row in _rows) {
      final pid = row.product!.id!;
      if (selectedProductIds.contains(pid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Duplicate products found: '${row.product!.name}' is selected multiple times. Please combine them into one row.",
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      selectedProductIds.add(pid);
    }

    // Show Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Order"),
        content: Text(
          "Are you sure you want to save this order?\n\nTotal Items: ${_rows.length}\nTotal Boxes: $_totalBoxes\nGrand Total: ₹${_grandTotal.toStringAsFixed(2)}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Build order items
      final List<OrderItem> items = _rows.map((row) {
        final product = row.product!;
        final qty = int.parse(row.quantityController.text);
        final price = double.parse(row.priceController.text);

        return OrderItem(
          productId: product.id!,
          quantity: qty,
          pricePerBox: price,
          totalAmount: price * qty,
          boxesAfterTransaction: 0, // Assigned inside service transaction
          productName: product.name,
          productBrand: product.brand,
          productSize: product.size,
          productVariety: product.variety,
        );
      }).toList();

      final Order order = Order(
        orderNumber: '', // Sequential number assigned by database
        orderDate: DateTime.now(),
        totalAmount: _grandTotal,
        totalBoxes: _totalBoxes,
        status: 'COMPLETED',
        remarks: _remarksController.text.trim(),
        createdAt: DateTime.now(),
        items: items,
      );

      await _orderService.saveOrder(order);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order saved successfully!"),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Error saving order: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Showroom Order"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    // Header Form details
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order number indicator & Date
                              Card(
                                elevation: 0.5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(
                                    color: AppColors.border,
                                    width: 0.5,
                                  ),
                                ),
                                color: AppColors.card,
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    children: [
                                      _buildHeaderInfoRow(
                                        "Order Number",
                                        "ORD-YYYYMMDD-XXXX (Auto-generated)",
                                      ),
                                      const Divider(height: 16),
                                      _buildHeaderInfoRow("Date & Time", todayStr),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                controller: _remarksController,
                                label: "Customer Remarks / Billing Details",
                                hint: "e.g., Client: Amit Shah, Phone: 9876543210, Invoice #932",
                                prefixIcon: Icons.notes,
                              ),
                              const SizedBox(height: 10),

                              const SectionTitle(title: "Order Items"),

                              // Dynamic Rows Builder
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _rows.length,
                                itemBuilder: (context, index) {
                                  return _buildOrderRow(index);
                                },
                              ),
                              const SizedBox(height: 12),

                              // Add another product button
                              TextButton.icon(
                                onPressed: _addRow,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text("Add Another Product"),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom sticky summary & Save button
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          )
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Boxes: $_totalBoxes",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  "Grand Total: ₹${_grandTotal.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              text: "Save Showroom Order",
                              isLoading: _isSaving,
                              onPressed: _saveOrder,
                              icon: Icons.receipt_long,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(int index) {
    final row = _rows[index];

    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Item #${index + 1}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                  onPressed: () => _removeRow(index),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Product Dropdown Selection
            DropdownButtonFormField<Product>(
              decoration: InputDecoration(
                labelText: "Select Tile Product",
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              initialValue: row.product,
              items: _products.map((p) {
                return DropdownMenuItem<Product>(
                  value: p,
                  child: Text(
                    "${p.name} (${p.brand}) • Size: ${p.size}",
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
              onChanged: (Product? selected) {
                setState(() {
                  row.product = selected;
                  if (selected != null) {
                    row.priceController.text = selected.sellingPricePerBox.toString();
                    if (row.quantityController.text.isEmpty) {
                      row.quantityController.text = "1";
                    }
                  }
                  _recalculateTotals();
                });
              },
              validator: (val) => val == null ? "Product selection is required" : null,
            ),
            const SizedBox(height: 12),

            // Display stock preview
            if (row.product != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: row.product!.boxesInStock <= 5
                      ? AppColors.lowStock.withValues(alpha: 0.1)
                      : AppColors.inStock.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 12,
                      color: row.product!.boxesInStock <= 5
                          ? AppColors.lowStock
                          : AppColors.inStock,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Available Stock: ${row.product!.boxesInStock} Boxes",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: row.product!.boxesInStock <= 5
                            ? AppColors.lowStock
                            : AppColors.inStock,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Pricing and quantity input fields
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: row.priceController,
                    label: "Price per Box (₹)",
                    hint: "0.00",
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Required";
                      }
                      final parsed = double.tryParse(val);
                      if (parsed == null || parsed <= 0) {
                        return "Must be > 0";
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: row.quantityController,
                    label: "Boxes Sold",
                    hint: "1",
                    keyboardType: TextInputType.number,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Required";
                      }
                      final qty = int.tryParse(val);
                      if (qty == null || qty <= 0) {
                        return "Must be > 0";
                      }
                      if (row.product != null && qty > row.product!.boxesInStock) {
                        return "Exceeds stock (${row.product!.boxesInStock})";
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            // Line total preview
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 4),
                child: Text(
                  "Line Total: ₹${row.lineTotal.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
