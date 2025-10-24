class AddExerciseRequest {
  final String exerciseId;
  final int orderIndex;
  final int plannedSets;
  final int plannedReps;
  final num? plannedWeight;
  final int? restSeconds;
  final String? tempo;
  final String? notes;
  final List<SetTemplateRequest> setTemplates;

  AddExerciseRequest({
    required this.exerciseId,
    required this.orderIndex,
    required this.plannedSets,
    required this.plannedReps,
    this.plannedWeight,
    this.restSeconds,
    this.tempo,
    this.notes,
    required this.setTemplates,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'orderIndex': orderIndex,
      'plannedSets': plannedSets,
      'plannedReps': plannedReps,
      if (plannedWeight != null) 'plannedWeight': plannedWeight,
      if (restSeconds != null) 'restSeconds': restSeconds,
      if (tempo != null) 'tempo': tempo,
      if (notes != null) 'notes': notes,
      'setTemplates': setTemplates.map((st) => st.toJson()).toList(),
    };
  }
}

class SetTemplateRequest {
  final int setNumber;
  final int plannedReps;
  final num? plannedWeight;
  final bool isWarmupSet;
  final String? notes;

  SetTemplateRequest({
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    required this.isWarmupSet,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'plannedReps': plannedReps,
      if (plannedWeight != null) 'plannedWeight': plannedWeight,
      'isWarmupSet': isWarmupSet,
      if (notes != null) 'notes': notes,
    };
  }
}
