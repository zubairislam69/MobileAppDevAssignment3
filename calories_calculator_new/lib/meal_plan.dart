import 'food_item.dart';

class meal_plan {
  final int id;
  final DateTime date;
  final int targetCalories;
  final List<food_item> selectedFoodItems;

  meal_plan(
      {required this.id,
      required this.date,
      required this.targetCalories,
      required this.selectedFoodItems});

  int get totalCalories {
    int sum = 0;
    for (var item in selectedFoodItems) {
      sum += item.calories;
    }
    return sum;
  }
}
