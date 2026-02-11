class Product {
  final String id;
  final String title;
  final String price;
  final String imageUrl;
  final String description;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.description,
  });

  // JSON data ko Product object mein convert karne ke liye
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      title: json['title'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      description: json['description'] ?? "No description available.",
    );
  }
}