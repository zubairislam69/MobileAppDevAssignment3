import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'DatabaseHelper.dart'; // Updated import
import 'food_item.dart';
import 'meal_plan.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CalorieTrackerHome(title: 'Calorie Tracker'),
    );
  }
}

class CalorieTrackerHome extends StatefulWidget {
  final String title;
  final meal_plan? initialMealPlan;

  const CalorieTrackerHome(
      {Key? key, required this.title, this.initialMealPlan})
      : super(key: key);

  @override
  _CalorieTrackerHomeState createState() => _CalorieTrackerHomeState();
}

class _CalorieTrackerHomeState extends State<CalorieTrackerHome> {
  int? targetCalories;
  DateTime selectedDate = DateTime.now();
  food_item? foodItem;
  List<food_item> setFoodItems = [];
  List<food_item> selectedFoodItems = [];
  late TextEditingController targetCaloriesController;

  @override
  void initState() {
    super.initState();
    _fetchFoodItems();

    targetCaloriesController = TextEditingController(
      text: widget.initialMealPlan?.targetCalories.toString() ?? '',
    );

    if (widget.initialMealPlan != null) {
      selectedDate = widget.initialMealPlan!.date;
      targetCalories = widget.initialMealPlan!.targetCalories;
      selectedFoodItems =
          List<food_item>.from(widget.initialMealPlan!.selectedFoodItems);
    }
  }

  @override
  void dispose() {
    targetCaloriesController.dispose();
    super.dispose();
  }

  int get totalMealCalories {
    int sum = 0;
    for (var item in selectedFoodItems) {
      sum += item.calories;
    }
    return sum;
  }

  Future<void> _fetchFoodItems() async {
    var foodItemsFromDB = await DatabaseHelper.instance.getFoodItems();
    setState(() {
      setFoodItems = foodItemsFromDB;
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2050),
    );
    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  void _addFoodItem() {
    if (foodItem != null) {
      setState(() {
        selectedFoodItems.add(foodItem!);
      });
    }
  }

  void _saveMealPlan() async {
    if (targetCalories == null || targetCalories! <= 0) {
      _showDialog('Error', 'Please enter your target calories.');
      return;
    }

    if (selectedFoodItems.isEmpty) {
      _showDialog('Error', 'Please add one or more food items.');
      return;
    }

    int totalCalories = 0;
    for (var item in selectedFoodItems) {
      totalCalories += item.calories;
    }

    if (totalCalories > targetCalories!) {
      _showDialog(
        'Error',
        'Total calories exceeds target calories.',
      );
      return;
    }

    bool isExistingMealPlan = await DatabaseHelper.instance
        .ifMealPlanExistsForDate(selectedDate, widget.initialMealPlan?.id);
    if (isExistingMealPlan) {
      _showDialog('Error',
          'Meal plan already available for this date. Either edit the current plan or choose a different date.');
      return;
    }

    if (widget.initialMealPlan != null) {
      await DatabaseHelper.instance.updateMealPlan(
        widget.initialMealPlan!.id,
        selectedDate,
        targetCalories!,
        selectedFoodItems,
      );
      _showDialog('Success', 'Your meal plan has been updated successfully.',
          success: true);
    } else {
      await DatabaseHelper.instance.addMealPlan(
        selectedDate,
        targetCalories!,
        selectedFoodItems,
      );
      _showDialog('Success', 'Your meal plan has been saved successfully.',
          success: true);
    }
  }

  void _showDialog(String title, String content, {bool success = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
                if (success && widget.initialMealPlan != null) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: targetCaloriesController,
                decoration: const InputDecoration(
                  labelText: 'Target Calories',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  targetCalories = int.tryParse(value);
                },
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _pickDate(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Select Date',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Calories: $totalMealCalories",
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontFamily: 'DMSerifDisplay', fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: DropdownButton<food_item>(
                  isExpanded: true,
                  hint: const Text('Pick a Food'),
                  value: foodItem,
                  onChanged: (food_item? newValue) {
                    setState(() {
                      foodItem = newValue;
                    });
                  },
                  items: setFoodItems
                      .map<DropdownMenuItem<food_item>>((food_item item) {
                    return DropdownMenuItem<food_item>(
                      value: item,
                      child: Text(item.name),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _addFoodItem,
                style: ElevatedButton.styleFrom(
                  primary: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: const Text(
                  'Save Food Item',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Text(
                    'Selected Foods',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedFoodItems.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(selectedFoodItems[index].name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${selectedFoodItems[index].calories} cal'),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                selectedFoodItems.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _saveMealPlan,
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Save Selection',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MealPlanListScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'View Meal Plans',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MealPlanListScreen extends StatefulWidget {
  static const routeName = '/list-meals';

  const MealPlanListScreen({Key? key}) : super(key: key);

  @override
  MealPlanListScreenState createState() => MealPlanListScreenState();
}

class MealPlanListScreenState extends State<MealPlanListScreen> {
  late Future<List<meal_plan>> mealPlans;

  @override
  void initState() {
    super.initState();
    mealPlans = DatabaseHelper.instance.getMealPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Meal Plans'),
      ),
      body: FutureBuilder<List<meal_plan>>(
        future: mealPlans,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.error != null) {
            return const Center(child: Text('An error occurred'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                meal_plan mealPlan = snapshot.data![index];
                String formattedDate =
                    DateFormat('yyyy-MM-dd').format(mealPlan.date);
                int totalCalories = mealPlan.totalCalories;

                // Inside the ListView.builder
                return Container(
                  margin: const EdgeInsets.all(8.0),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    border: Border.all(color: Colors.black, width: 1.0),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    title: Text("$formattedDate"),
                    subtitle: Text(
                      "Target Calories: ${mealPlan.targetCalories}\nTotal Calories: $totalCalories",
                    ),
                    onTap: () => _showMealPlanOptions(context, mealPlan),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No meal plans found'));
          }
        },
      ),
    );
  }

  void _showMealPlanOptions(BuildContext context, meal_plan mealPlan) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 120,
          child: Column(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CalorieTrackerHome(
                        title: 'Edit Meal Plan',
                        initialMealPlan: mealPlan,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  await DatabaseHelper.instance.deleteMealPlan(mealPlan.id);
                  Navigator.pop(context);
                  setState(() {
                    mealPlans = DatabaseHelper.instance.getMealPlans();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
