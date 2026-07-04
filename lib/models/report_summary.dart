import '../models/product.dart';

class ProductSalesSummary {
  final int productId;
  final String name;
  final String brand;
  final int boxesSold;
  final double revenue;

  const ProductSalesSummary({
    required this.productId,
    required this.name,
    required this.brand,
    required this.boxesSold,
    required this.revenue,
  });
}

class BrandSalesSummary {
  final String brand;
  final int productCount;
  final int boxesSold;
  final double revenue;

  const BrandSalesSummary({
    required this.brand,
    required this.productCount,
    required this.boxesSold,
    required this.revenue,
  });
}

class SizeSalesSummary {
  final String size;
  final int productCount;
  final int boxesSold;
  final double revenue;

  const SizeSalesSummary({
    required this.size,
    required this.productCount,
    required this.boxesSold,
    required this.revenue,
  });
}

class VarietySalesSummary {
  final String variety;
  final int productCount;
  final int boxesSold;
  final double revenue;

  const VarietySalesSummary({
    required this.variety,
    required this.productCount,
    required this.boxesSold,
    required this.revenue,
  });
}

class OrderReportSummary {
  final DateTime startDate;
  final DateTime endDate;

  // Global counts
  final int totalProducts;
  final int totalBoxesInStock;
  final int lowStockCount;

  // Period performance metrics
  final int totalOrders;
  final double totalRevenue;
  final int totalBoxesSold;
  final double averageOrderValue;
  final double highestOrder;
  final double lowestOrder;
  final int cancelledOrdersCount;

  // Period lists
  final List<ProductSalesSummary> productSales;
  final List<BrandSalesSummary> brandSales;
  final List<SizeSalesSummary> sizeSales;
  final List<VarietySalesSummary> varietySales;

  // Inventory lists
  final List<Product> currentStockList;
  final List<Product> lowStockList;
  final List<Product> outOfStockList;

  const OrderReportSummary({
    required this.startDate,
    required this.endDate,
    required this.totalProducts,
    required this.totalBoxesInStock,
    required this.lowStockCount,
    required this.totalOrders,
    required this.totalRevenue,
    required this.totalBoxesSold,
    required this.averageOrderValue,
    required this.highestOrder,
    required this.lowestOrder,
    required this.cancelledOrdersCount,
    required this.productSales,
    required this.brandSales,
    required this.sizeSales,
    required this.varietySales,
    required this.currentStockList,
    required this.lowStockList,
    required this.outOfStockList,
  });
}
