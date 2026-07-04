import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/product.dart';
import '../../models/report_summary.dart';
import '../../services/report_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/section_title.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ReportService _reportService = ReportService();
  final SettingsService _settingsService = SettingsService();

  OrderReportSummary? _reportSummary;
  bool _isLoading = true;
  String _selectedPeriod = 'Weekly'; // 'Daily', 'Weekly', 'Monthly', 'Custom'
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  int _lowStockLimit = 5;

  // Search query inside movements tab
  final TextEditingController _searchController = TextEditingController();
  String _productQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final settings = await _settingsService.getSettings();
      final summary = await _reportService.getReportSummary(
        _startDate,
        _endDate,
        lowStockLimit: settings.lowStockLimit,
      );
      setState(() {
        _lowStockLimit = settings.lowStockLimit;
        _reportSummary = summary;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading report: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to generate order reports"),
            backgroundColor: AppColors.error,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);

      if (period == 'Daily') {
        _startDate = todayMidnight;
        _endDate = todayMidnight;
        _loadReport();
      } else if (period == 'Weekly') {
        _startDate = todayMidnight.subtract(const Duration(days: 7));
        _endDate = now;
        _loadReport();
      } else if (period == 'Monthly') {
        _startDate = todayMidnight.subtract(const Duration(days: 30));
        _endDate = now;
        _loadReport();
      } else if (period == 'Custom') {
        _selectCustomDateRange();
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
      _loadReport();
    }
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Export Sales Report",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Select file format to export this period's order ledger. (Export functions are placeholders for future upgrades)",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                  title: const Text("Export as PDF Invoice Ledger"),
                  subtitle: const Text("Includes brand sales summaries"),
                  onTap: () {
                    Navigator.pop(context);
                    _simulatedExport("PDF");
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_view, color: Colors.green),
                  title: const Text("Export as Excel (CSV) Spreadsheet"),
                  subtitle: const Text("Raw orders database matching date range"),
                  onTap: () {
                    Navigator.pop(context);
                    _simulatedExport("Excel");
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _simulatedExport(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Exporting as $format is prepared and will be supported in future versions."),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeStr =
        "${DateFormat('dd MMM yy').format(_startDate)} - ${DateFormat('dd MMM yy').format(_endDate)}";

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports & Sales Analytics"),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: "Export ledger",
              onPressed: _showExportOptions,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Report",
              onPressed: _loadReport,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Analytics", icon: Icon(Icons.analytics_outlined)),
              Tab(text: "Sales Feed", icon: Icon(Icons.shopping_cart_outlined)),
              Tab(text: "Inventory", icon: Icon(Icons.inventory_2_outlined)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Period Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPeriodChip("Daily"),
                          const SizedBox(width: 8),
                          _buildPeriodChip("Weekly"),
                          const SizedBox(width: 8),
                          _buildPeriodChip("Monthly"),
                          const SizedBox(width: 8),
                          _buildPeriodChip("Custom"),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          dateRangeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Tab contents
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildAnalyticsTab(),
                        _buildSalesFeedTab(),
                        _buildInventoryTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) _changePeriod(label);
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  // TAB 1: ANALYTICS (Dashboard Metrics + Group sales tables)
  Widget _buildAnalyticsTab() {
    if (_reportSummary == null) return const SizedBox.shrink();

    final r = _reportSummary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: "Sales Performance"),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildReportCard("Completed Orders", r.totalOrders.toString(), Icons.receipt_long, AppColors.primary),
              _buildReportCard("Total Revenue", "₹${r.totalRevenue.toStringAsFixed(0)}", Icons.currency_rupee, AppColors.success),
              _buildReportCard("Boxes Sold", "${r.totalBoxesSold} Box", Icons.shopping_basket_outlined, AppColors.primary),
              _buildReportCard("Avg Order Value", "₹${r.averageOrderValue.toStringAsFixed(0)}", Icons.analytics_outlined, AppColors.primary),
              _buildReportCard("Highest Invoice", "₹${r.highestOrder.toStringAsFixed(0)}", Icons.trending_up, AppColors.success),
              _buildReportCard("Lowest Invoice", "₹${r.lowestOrder.toStringAsFixed(0)}", Icons.trending_down, AppColors.primary),
              _buildReportCard("Cancelled Orders", r.cancelledOrdersCount.toString(), Icons.cancel_presentation_outlined, r.cancelledOrdersCount > 0 ? AppColors.error : AppColors.primary),
              _buildReportCard("Low Stock Alert", r.lowStockCount.toString(), Icons.warning_amber_outlined, r.lowStockCount > 0 ? AppColors.lowStock : AppColors.primary),
            ],
          ),
          const SizedBox(height: 24),

          const SectionTitle(title: "Brand-wise Sales Performance"),
          _buildBrandTable(r.brandSales),
          const SizedBox(height: 24),

          const SectionTitle(title: "Size-wise Sales Performance"),
          _buildSizeTable(r.sizeSales),
          const SizedBox(height: 24),

          const SectionTitle(title: "Variety-wise Sales Performance"),
          _buildVarietyTable(r.varietySales),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    color: color == AppColors.error || color == AppColors.lowStock
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

  Widget _buildBrandTable(List<BrandSalesSummary> summaries) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("No brand sales recorded in this period")),
        ),
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text("Brand", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Tiles Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Boxes Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Revenue (₹)", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: summaries.map((b) {
            return DataRow(cells: [
              DataCell(Text(b.brand, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(b.productCount.toString())),
              DataCell(Text("${b.boxesSold} Box")),
              DataCell(Text(
                "₹${b.revenue.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSizeTable(List<SizeSalesSummary> summaries) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("No size sales recorded in this period")),
        ),
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text("Size", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Tiles Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Boxes Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Revenue (₹)", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: summaries.map((s) {
            return DataRow(cells: [
              DataCell(Text(s.size, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(s.productCount.toString())),
              DataCell(Text("${s.boxesSold} Box")),
              DataCell(Text(
                "₹${s.revenue.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVarietyTable(List<VarietySalesSummary> summaries) {
    if (summaries.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text("No variety sales recorded in this period")),
        ),
      );
    }

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      color: AppColors.card,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.background),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text("Variety", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Tiles Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Boxes Sold", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Revenue (₹)", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: summaries.map((v) {
            return DataRow(cells: [
              DataCell(Text(v.variety, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(v.productCount.toString())),
              DataCell(Text("${v.boxesSold} Box")),
              DataCell(Text(
                "₹${v.revenue.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // TAB 2: SALES FEED (Product-wise summary list of boxes and revenues)
  Widget _buildSalesFeedTab() {
    if (_reportSummary == null) return const SizedBox.shrink();

    final filteredList = _reportSummary!.productSales.where((item) {
      final q = _productQuery.toLowerCase().trim();
      return item.name.toLowerCase().contains(q) ||
          item.brand.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _productQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: "Search tiles or brand...",
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        // Product wise summaries
        Expanded(
          child: filteredList.isEmpty
              ? const Center(child: Text("No product sales summaries found"))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    return Card(
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border, width: 0.5),
                      ),
                      color: AppColors.card,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${item.brand} • Boxes Sold: ${item.boxesSold} Box",
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "₹${item.revenue.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // TAB 3: INVENTORY STATUS (Current, Low stock warnings, Out of stock)
  Widget _buildInventoryTab() {
    if (_reportSummary == null) return const SizedBox.shrink();

    final r = _reportSummary!;

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: [
                Tab(text: "Current Stock"),
                Tab(text: "Low Stock"),
                Tab(text: "Out of Stock"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductList(r.currentStockList),
                _buildProductList(r.lowStockList),
                _buildProductList(r.outOfStockList),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              "No products in this category",
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final isLow = p.boxesInStock <= _lowStockLimit;
        final isOut = p.boxesInStock == 0;

        return Card(
          elevation: 0.5,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 0.5),
          ),
          color: AppColors.card,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${p.brand} • Size: ${p.size} • Var: ${p.variety}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOut
                        ? AppColors.error.withValues(alpha: 0.1)
                        : isLow
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.inStock.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "${p.boxesInStock} Box",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isOut
                          ? AppColors.error
                          : isLow
                              ? AppColors.warning
                              : AppColors.inStock,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
