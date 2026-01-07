class NutritionHistoryResponse {
  final NutritionSession session;
  final List<NutritionHistoryLog> logs;

  NutritionHistoryResponse({
    required this.session,
    required this.logs,
  });

  factory NutritionHistoryResponse.fromJson(Map<String, dynamic> json) {
    return NutritionHistoryResponse(
      session: NutritionSession.fromJson(json['session']),
      logs: (json['logs'] as List? ?? [])
          .map((e) => NutritionHistoryLog.fromJson(e))
          .toList(),
    );
  }
}

class NutritionSession {
  final String id;
  final String mealType;
  final DateTime date;
  final String? caption;
  final List<String> images;

  NutritionSession({
    required this.id,
    required this.mealType,
    required this.date,
    this.caption,
    this.images = const [],
  });

  factory NutritionSession.fromJson(Map<String, dynamic> json) {
    return NutritionSession(
      id: json['id'] as String,
      mealType: json['mealType'] as String? ?? 'Meal',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      caption: json['caption'] as String?,
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class NutritionHistoryLog {
  final String id;
  final String? foodId;
  final int quantity;
  final String mealType;
  final DateTime createdAt;
  final String? foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  NutritionHistoryLog({
    required this.id,
    this.foodId,
    this.quantity = 1,
    required this.mealType,
    required this.createdAt,
    this.foodName,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  factory NutritionHistoryLog.fromJson(Map<String, dynamic> json) {
    return NutritionHistoryLog(
      id: json['id'] as String,
      foodId: json['foodId'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      mealType: json['mealType'] as String? ?? 'Meal',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      foodName: json['foodName'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }
}
