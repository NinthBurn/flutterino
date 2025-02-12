
class ComputerComponent {
  int id;
  String name;
  String manufacturer;
  String category;
  double price;
  int quantity;
  DateTime releaseDate;

  ComputerComponent.full({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.price,
    required this.quantity,
    required this.releaseDate
  });

  ComputerComponent({
    required this.name,
    required this.manufacturer,
    required this.category,
    required this.price,
    required this.quantity,
    required this.releaseDate
  }) : id=-1;

  factory ComputerComponent.fromJson(Map<String, dynamic> json) {
    return ComputerComponent.full(
      id: json['product_id'] as int,
      name: json['product_name'] as String,
      manufacturer: json['manufacturer'] as String,
      category: json['category'] as String,
      price: json['price'] * 1.0,
      quantity: json['quantity'] as int,
      releaseDate: DateTime.parse(json['release_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': id,
      'product_name': name,
      'manufacturer': manufacturer,
      'category': category,
      'price': price,
      'quantity': quantity,
      'release_date': releaseDate.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonWithoutId() {
    return {
      'product_name': name,
      'manufacturer': manufacturer,
      'category': category,
      'price': price,
      'quantity': quantity,
      'release_date': releaseDate.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComputerComponent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;


  @override
  String toString() {
    return 'ComputerComponent{id: $id, name: $name, manufacturer: $manufacturer, category: $category, price: $price, quantity: $quantity, releaseDate: $releaseDate}';
  }
}