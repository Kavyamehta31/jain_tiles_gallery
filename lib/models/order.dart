class OrderItem {
  final int? id;
  final int? orderId;
  final int productId;
  final int quantity;
  final double pricePerBox;
  final double totalAmount;
  final int boxesAfterTransaction;

  // Product snapshot fields (persists historical data even if product is deleted/edited)
  final String productName;
  final String productBrand;
  final String productSize;
  final String productVariety;

  const OrderItem({
    this.id,
    this.orderId,
    required this.productId,
    required this.quantity,
    required this.pricePerBox,
    required this.totalAmount,
    required this.boxesAfterTransaction,
    required this.productName,
    required this.productBrand,
    required this.productSize,
    required this.productVariety,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'price_per_box': pricePerBox,
      'total_amount': totalAmount,
      'boxes_after_transaction': boxesAfterTransaction,
      'product_name': productName,
      'product_brand': productBrand,
      'product_size': productSize,
      'product_variety': productVariety,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as int?,
      orderId: map['order_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      pricePerBox: (map['price_per_box'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      boxesAfterTransaction: map['boxes_after_transaction'] as int,
      productName: map['product_name'] as String,
      productBrand: map['product_brand'] as String,
      productSize: map['product_size'] as String,
      productVariety: map['product_variety'] as String,
    );
  }
}

class Order {
  final int? id;
  final String orderNumber;
  final DateTime orderDate;
  final double totalAmount;
  final int totalBoxes;
  final String status; // 'COMPLETED', 'CANCELLED'
  final String remarks;
  final DateTime createdAt;
  final List<OrderItem> items;

  const Order({
    this.id,
    required this.orderNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.totalBoxes,
    required this.status,
    required this.remarks,
    required this.createdAt,
    this.items = const [],
  });

  Order copyWith({
    int? id,
    String? orderNumber,
    DateTime? orderDate,
    double? totalAmount,
    int? totalBoxes,
    String? status,
    String? remarks,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      totalAmount: totalAmount ?? this.totalAmount,
      totalBoxes: totalBoxes ?? this.totalBoxes,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      'total_amount': totalAmount,
      'total_boxes': totalBoxes,
      'status': status,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, {List<OrderItem> items = const []}) {
    return Order(
      id: map['id'] as int?,
      orderNumber: map['order_number'] as String,
      orderDate: DateTime.parse(map['order_date'] as String),
      totalAmount: (map['total_amount'] as num).toDouble(),
      totalBoxes: map['total_boxes'] as int,
      status: (map['status'] ?? 'COMPLETED') as String,
      remarks: (map['remarks'] ?? '') as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      items: items,
    );
  }
}
