import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a single meal in a daily meal plan
class MealItemModel {
  final String type; // 'Bữa sáng', 'Bữa trưa', 'Bữa tối'
  final String name;
  final int calories;
  final String imageUrl;
  final List<String> swaps;
  final List<String> instructions;

  const MealItemModel({
    required this.type,
    required this.name,
    required this.calories,
    required this.imageUrl,
    required this.swaps,
    required this.instructions,
  });

  factory MealItemModel.fromJson(Map<String, dynamic> json) {
    return MealItemModel(
      type: json['type']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url']?.toString() ?? '',
      swaps: (json['swaps'] as List?)?.map((e) => e.toString()).toList() ?? [],
      instructions: (json['instructions'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'calories': calories,
      'image_url': imageUrl,
      'swaps': swaps,
      'instructions': instructions,
    };
  }

  MealItemModel copyWith({
    String? name,
    int? calories,
    String? imageUrl,
    List<String>? swaps,
    List<String>? instructions,
  }) {
    return MealItemModel(
      type: type,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      imageUrl: imageUrl ?? this.imageUrl,
      swaps: swaps ?? this.swaps,
      instructions: instructions ?? this.instructions,
    );
  }
}

/// Model for a grocery item
class GroceryItemModel {
  final String name;
  final String qty;
  final bool checked;

  const GroceryItemModel({
    required this.name,
    required this.qty,
    required this.checked,
  });

  factory GroceryItemModel.fromJson(Map<String, dynamic> json) {
    return GroceryItemModel(
      name: json['name']?.toString() ?? '',
      qty: json['qty']?.toString() ?? '',
      checked: json['checked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'qty': qty,
      'checked': checked,
    };
  }

  GroceryItemModel copyWith({bool? checked}) {
    return GroceryItemModel(
      name: name,
      qty: qty,
      checked: checked ?? this.checked,
    );
  }
}

/// Model for a daily meal plan document
class MealPlanModel {
  final String date; // 'yyyy-MM-dd'
  final List<MealItemModel> meals;
  final Map<String, List<GroceryItemModel>> groceryList;

  const MealPlanModel({
    required this.date,
    required this.meals,
    required this.groceryList,
  });

  factory MealPlanModel.fromJson(Map<String, dynamic> json) {
    // Parse meals
    final rawMeals = json['meals'] as List? ?? [];
    final meals = rawMeals
        .map((m) => MealItemModel.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // Parse grocery list
    final rawGrocery = json['grocery_list'] as Map<String, dynamic>? ?? {};
    final groceryList = <String, List<GroceryItemModel>>{};
    for (final entry in rawGrocery.entries) {
      final items = (entry.value as List?)
              ?.map((i) => GroceryItemModel.fromJson(Map<String, dynamic>.from(i)))
              .toList() ??
          [];
      groceryList[entry.key] = items;
    }

    return MealPlanModel(
      date: json['date']?.toString() ?? '',
      meals: meals,
      groceryList: groceryList,
    );
  }

  Map<String, dynamic> toJson() {
    final groceryJson = <String, dynamic>{};
    for (final entry in groceryList.entries) {
      groceryJson[entry.key] = entry.value.map((i) => i.toJson()).toList();
    }

    return {
      'date': date,
      'meals': meals.map((m) => m.toJson()).toList(),
      'grocery_list': groceryJson,
    };
  }
}
