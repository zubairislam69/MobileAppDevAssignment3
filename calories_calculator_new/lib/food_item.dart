class food_item {
  final int id;
  final String name;
  final int calories;

  food_item({required this.id, required this.name, required this.calories});

  // Factory method to create a food item from a map
  factory food_item.fromMap(Map<String, dynamic> map) {
    return food_item(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
    );
  }

  // Convert the food item to a map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
    };
  }
}
