class InventoryItem {
  final String id;
  final String userId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String? category;

  InventoryItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String documentId) {
    return InventoryItem(
      id: documentId,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'],
      category: map['category'],
    );
  }

  InventoryItem copyWith({
    String? id,
    String? userId,
    String? name,
    int? quantity,
    double? price,
    String? imageUrl,
    String? category,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}
