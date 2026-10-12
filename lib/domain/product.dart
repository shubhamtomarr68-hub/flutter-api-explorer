import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final price = json['price'];
    if (id is! int || title is! String || title.isEmpty || price is! num) {
      throw const FormatException('Product JSON is missing required fields');
    }
    return Product(
      id: id,
      title: title,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Unknown',
      price: price.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      thumbnail: json['thumbnail'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    price,
    rating,
    stock,
    thumbnail,
  ];
}

class ProductPage extends Equatable {
  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final raw = json['products'];
    final total = json['total'];
    final skip = json['skip'];
    final limit = json['limit'];
    if (raw is! List || total is! int || skip is! int || limit is! int) {
      throw const FormatException(
        'Product page JSON is missing required fields',
      );
    }
    return ProductPage(
      products: raw.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Product page contains a non-object');
        }
        return Product.fromJson(item);
      }).toList(),
      total: total,
      skip: skip,
      limit: limit,
    );
  }

  @override
  List<Object?> get props => [products, total, skip, limit];
}
