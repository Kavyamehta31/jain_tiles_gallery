class Product {
  final int? id;
  final String name;
  final String brand;
  final String size;
  final String variety;
  final int boxesInStock;
  final int piecesPerBox;
  final double sellingPricePerBox;
  final String description;
  final List<String> imagePaths;

  const Product({
    this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.variety,
    required this.boxesInStock,
    required this.piecesPerBox,
    this.sellingPricePerBox = 0.0,
    required this.description,
    this.imagePaths = const [],
  });

  Product copyWith({
    int? id,
    String? name,
    String? brand,
    String? size,
    String? variety,
    int? boxesInStock,
    int? piecesPerBox,
    double? sellingPricePerBox,
    String? description,
    List<String>? imagePaths,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      variety: variety ?? this.variety,
      boxesInStock: boxesInStock ?? this.boxesInStock,
      piecesPerBox: piecesPerBox ?? this.piecesPerBox,
      sellingPricePerBox: sellingPricePerBox ?? this.sellingPricePerBox,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'size': size,
      'variety': variety,
      'boxes_in_stock': boxesInStock,
      'pieces_per_box': piecesPerBox,
      'selling_price_per_box': sellingPricePerBox,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<String> imagePaths = const []}) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String,
      size: map['size'] as String,
      variety: map['variety'] as String,
      boxesInStock: map['boxes_in_stock'] as int,
      piecesPerBox: map['pieces_per_box'] as int,
      sellingPricePerBox: (map['selling_price_per_box'] as num?)?.toDouble() ?? 0.0,
      description: (map['description'] ?? '') as String,
      imagePaths: imagePaths,
    );
  }
}
