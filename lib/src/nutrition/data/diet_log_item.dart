class DietLogItem {
  String? foodId;
  String name;
  int quantity;
  int calories;
  double protein;
  double fat;
  double carbs;

  // Track original values to check for modifications
  int? originalCalories;
  double? originalProtein;
  double? originalFat;
  double? originalCarbs;

  DietLogItem({
    this.foodId,
    this.name = '',
    this.quantity = 1,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.originalCalories,
    this.originalProtein,
    this.originalFat,
    this.originalCarbs,
  });
}
