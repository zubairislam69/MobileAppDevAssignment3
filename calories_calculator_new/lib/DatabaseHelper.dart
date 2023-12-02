import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:convert';
import 'dart:io';
import 'food_item.dart';
import 'meal_plan.dart';

class DatabaseHelper {
  // Database details
  static const String dbName = 'caloriesCalculator.db';
  static const int dbVersion = 1;
  static const String foodItemsTable = 'foodItems';
  static const String mealPlanTable = 'foodSchedule';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Getter for the database
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future _initDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/$dbName';
    return await openDatabase(path, version: dbVersion, onCreate: _onCreate);
  }

  // Create tables and insert initial food items
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $foodItemsTable (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $mealPlanTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        targetCalories INTEGER NOT NULL,
        selectedFoodItems TEXT NOT NULL
      )
    ''');

    await _insertFoodItems(db);
  }

  // Insert initial food items
  Future _insertFoodItems(Database db) async {
    List<Map<String, dynamic>> initialFoodItems = [
      {'id': 1, 'name': 'Apple', 'calories': 59},
      {'id': 2, 'name': 'Banana', 'calories': 151},
      {'id': 3, 'name': 'Orange', 'calories': 53},
      {'id': 4, 'name': 'Asparagus', 'calories': 27},
      {'id': 5, 'name': 'Ice Coffee', 'calories': 100},
      {'id': 6, 'name': 'Carrots', 'calories': 50},
      {'id': 7, 'name': 'Cucumber', 'calories': 17},
      {'id': 8, 'name': 'Eggplant', 'calories': 35},
      {'id': 9, 'name': 'Dark Chocolate', 'calories': 155},
      {'id': 10, 'name': 'Corn', 'calories': 132},
      {'id': 11, 'name': 'Potato', 'calories': 130},
      {'id': 12, 'name': 'Rice', 'calories': 206},
      {'id': 13, 'name': 'Sandwich', 'calories': 200},
      {'id': 14, 'name': 'Diet Coke', 'calories': 0},
      {'id': 15, 'name': 'Milk', 'calories': 102},
      {'id': 16, 'name': 'Apple cider', 'calories': 117},
      {'id': 17, 'name': 'Yogurt', 'calories': 110},
    ];

    for (var item in initialFoodItems) {
      await db.insert(foodItemsTable, item);
    }
  }

  // Add a meal plan to the database
  Future<int> addMealPlan(DateTime date, int targetCalories,
      List<food_item> selectedFoodItems) async {
    Database db = await database;
    String foodItemsJson =
        jsonEncode(selectedFoodItems.map((item) => item.toMap()).toList());

    return await db.insert(mealPlanTable, {
      'date': date.toIso8601String(),
      'targetCalories': targetCalories,
      'selectedFoodItems': foodItemsJson
    });
  }

  // Update a meal plan in the database
  Future<int> updateMealPlan(int id, DateTime date, int targetCalories,
      List<food_item> selectedFoodItems) async {
    Database db = await database;
    String foodItemsJson =
        jsonEncode(selectedFoodItems.map((item) => item.toMap()).toList());

    return await db.update(
        mealPlanTable,
        {
          'date': date.toIso8601String(),
          'targetCalories': targetCalories,
          'selectedFoodItems': foodItemsJson
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  // Delete a meal plan from the database
  Future<int> deleteMealPlan(int id) async {
    Database db = await database;
    return await db.delete(mealPlanTable, where: 'id = ?', whereArgs: [id]);
  }

  // Get a list of food items from the database
  Future<List<food_item>> getFoodItems() async {
    Database db = await database;
    var foodItems = await db.query(foodItemsTable);
    return List.generate(foodItems.length, (i) {
      return food_item(
        id: foodItems[i]['id'] as int,
        name: foodItems[i]['name'] as String,
        calories: foodItems[i]['calories'] as int,
      );
    });
  }

  // Get a list of meal plans from the database
  Future<List<meal_plan>> getMealPlans() async {
    Database db = await database;
    var mealPlansData = await db.query(mealPlanTable, orderBy: 'date DESC');

    List<meal_plan> mealPlans = [];
    for (var mealPlanData in mealPlansData) {
      String selectedFoodItemsJson =
          mealPlanData['selectedFoodItems'] as String;
      List<food_item> foodItems = (jsonDecode(selectedFoodItemsJson) as List)
          .map((item) => food_item.fromMap(Map<String, dynamic>.from(item)))
          .toList();

      meal_plan mealPlan = meal_plan(
        id: mealPlanData['id'] as int,
        date: DateTime.parse(mealPlanData['date'] as String),
        targetCalories: mealPlanData['targetCalories'] as int,
        selectedFoodItems: foodItems,
      );
      mealPlans.add(mealPlan);
    }

    return mealPlans;
  }

  // Check if a meal plan exists for a given date
  Future<bool> ifMealPlanExistsForDate(DateTime date, int? excludingId) async {
    Database db = await database;
    List<Map> result = await db.query(
      mealPlanTable,
      where: 'date = ? AND id != ?',
      whereArgs: [date.toIso8601String(), excludingId ?? -1],
    );
    return result.isNotEmpty;
  }

  // Method to delete the database file
  Future<void> deleteDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = '${directory.path}/$dbName';

    // Use File class to delete the database file
    File databaseFile = File(path);
    if (await databaseFile.exists()) {
      await databaseFile.delete();
    }

    _database =
        null; // Set _database to null to trigger its recreation on the next call.
  }
}
