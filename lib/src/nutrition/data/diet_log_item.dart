class DietLogItem {
  String? foodId;
  String name;
  int quantity;
  int calories;
  double protein;
  double fat;
  double carbs;
  double fiber;

  // Track original values to check for modifications
  int? originalCalories;
  double? originalProtein;
  double? originalFat;
  double? originalCarbs;
  
  // Cal AI fields
  String? imagePath;
  bool isLoading;

  DietLogItem({
    this.foodId,
    this.name = '',
    this.quantity = 1,
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.originalCarbs,
    this.imagePath,
    this.isLoading = false,
  });
}
