import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/settings_model.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/settings_service.dart';
import '../entry/new_order_screen.dart';
import '../products/products_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OrderService _orderService = OrderService();
  final ProductService _productService = ProductService();
  final SettingsService _settingsService = SettingsService();

  SettingsModel? _settings;
  Map<String, dynamic> _stats = {
    'products': 0,
    'stock': 0,
    'lowStock': 0,
    'todayOrdersCount': 0,
    'todayRevenue': 0.0,
    'todayBoxes': 0,
    'monthRevenue': 0.0,
  };
  List<Product> _lowStockProducts = [];
  List<Order> _recentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.getSettings();
      
      // Load order stats
      final stats = await _orderService.getDashboardStats(
        lowStockLimit: settings.lowStockLimit,
      );

      // Load products for low stock alert list
      final allProducts = await _productService.getProducts();
      final lowStockProds = allProducts
          .where((p) => p.boxesInStock <= settings.lowStockLimit)
          .toList();

      // Load recent orders
      final recentOrders = await _orderService.getRecentOrders(5);

      setState(() {
        _settings = settings;
        _stats = stats;
        _lowStockProducts = lowStockProds;
        _recentOrders = recentOrders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading dashboard stats: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showLogo = _settings?.shopLogoPath.isNotEmpty == true &&
        File(_settings!.shopLogoPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _settings?.shopName ?? "Jain Tiles Gallery",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: showLogo
            ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: FileImage(File(_settings!.shopLogoPath)),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: "Refresh Dashboard",
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadStats();
            },
            tooltip: "Showroom Settings",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back,",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Text(
                    "Showroom Sales Overview",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Stats Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.45,
                    children: [
                      DashboardStatsCard(
                        title: "Today's Revenue",
                        value: "₹${(_stats['todayRevenue'] as double).toStringAsFixed(0)}",
                        icon: Icons.currency_rupee,
                        color: AppColors.success,
                      ),
                      DashboardStatsCard(
                        title: "Today's Orders",
                        value: _stats['todayOrdersCount'].toString(),
                        icon: Icons.receipt_long_outlined,
                        color: AppColors.primary,
                      ),
                      DashboardStatsCard(
                        title: "Today's Boxes Sold",
                        value: "${_stats['todayBoxes']} Box",
                        icon: Icons.shopping_basket_outlined,
                        color: AppColors.primary,
                      ),
                      DashboardStatsCard(
                        title: "Month Revenue",
                        value: "₹${(_stats['monthRevenue'] as double).toStringAsFixed(0)}",
                        icon: Icons.bar_chart_outlined,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Quick Actions
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickActionBtn(
                        label: "New Order",
                        icon: Icons.receipt_long,
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewOrderScreen(),
                            ),
                          );
                          if (result == true) _loadStats();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionBtn(
                        label: "Products",
                        icon: Icons.inventory_2_outlined,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductsScreen(),
                            ),
                          );
                          _loadStats();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionBtn(
                        label: "Reports",
                        icon: Icons.bar_chart,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReportsScreen(),
                            ),
                          );
                          _loadStats();
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionBtn(
                        label: "Settings",
                        icon: Icons.settings_outlined,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                          _loadStats();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Low Stock Alerts Panel
                  if (_lowStockProducts.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Low Stock Alert",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.lowStock,
                          ),
                        ),
                        Text(
                          "${_lowStockProducts.length} Items Running Low",
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _lowStockProducts.length,
                        itemBuilder: (context, index) {
                          final p = _lowStockProducts[index];
                          return Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.lowStock.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.lowStock.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.brand,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 12,
                                      color: AppColors.lowStock,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${p.boxesInStock} Boxes Left",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.lowStock,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 4. Recent Activity (Recent Orders)
                  const Text(
                    "Recent Orders",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_recentOrders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          "No orders recorded yet.",
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentOrders.length,
                      itemBuilder: (context, index) {
                        final order = _recentOrders[index];
                        final isCancelled = order.status == 'CANCELLED';
                        final dateStr = DateFormat('dd MMM, hh:mm a')
                            .format(order.orderDate);

                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 0.5,
                            ),
                          ),
                          color: AppColors.card,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderNumber,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          decoration: isCancelled
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: isCancelled
                                              ? AppColors.textSecondary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "$dateStr • ${order.items.length} Items",
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "₹${order.totalAmount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isCancelled
                                            ? AppColors.textSecondary
                                            : AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? AppColors.error
                                                .withValues(alpha: 0.08)
                                            : AppColors.success
                                                .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: isCancelled
                                              ? AppColors.error
                                              : AppColors.success,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickActionBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          foregroundColor: AppColors.primary,
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 22, color: color),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color == AppColors.lowStock
                        ? color
                        : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
