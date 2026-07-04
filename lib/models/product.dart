class Product {
  final int? id;
  final String name;
  final String brand;
  final String size;
  final String variety;
  final int quantity;
  final int piecesPerBox;
  final String? description;

  Product({
    this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.variety,
    required this.quantity,
    required this.piecesPerBox,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'size': size,
      'variety': variety,
      'quantity': quantity,
      'pieces_per_box': piecesPerBox,
      'description': description,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      brand: map['brand'],
      size: map['size'],
      variety: map['variety'],
      quantity: map['quantity'],
      piecesPerBox: map['pieces_per_box'],
      description: map['description'],
    );
  }
}
  