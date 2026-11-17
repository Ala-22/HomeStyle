class ProductModel {
  final int id;

  final String name;

  final String description;

  final double price;

  final String image;

  final String category;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
  });

  bool get hasDiscount => id % 3 == 0;

  double get discountedPrice =>
      hasDiscount ? (price * 0.80) : price;

  double? get oldPrice => hasDiscount ? price : null;

  String get priceLabel =>
      '\$${discountedPrice.toStringAsFixed(2)}';

  int get rating => 4 + (id % 2);

  int get reviewsCount => 20 + (id * 7) % 180;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.parse(json['price'].toString()),
      image: json['image'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category,
    };
  }
}