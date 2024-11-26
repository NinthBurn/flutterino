
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