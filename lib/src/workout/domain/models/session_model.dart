class WorkoutSession {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final bool isPublic;
  final String? notes;
  final bool isActive;
  final String? lastWorkoutLogId; // NEW: nullable last workout log id
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<SessionExercise> sessionExercises;

  WorkoutSession({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.isPublic,
    this.notes,
    required this.isActive,
    this.lastWorkoutLogId, // NEW
    required this.createdAt,
    this.updatedAt,
    required this.sessionExercises,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      lastWorkoutLogId: json['lastWorkoutLogId'] as String?, // NEW parsing
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      sessionExercises: (json['sessionExercises'] as List<dynamic>?)
              ?.map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SessionExercise {
  final String id;
  final String workoutSessionId;
  final String exerciseId;
  final int orderIndex;
  final int plannedSets;
  final int plannedReps;
  final num? plannedWeight;
  final int? restSeconds;
  final String? tempo;
  final String? notes;
  final Exercise? exercise;
  final List<SetTemplate> setTemplates;

  SessionExercise({
    required this.id,
    required this.workoutSessionId,
    required this.exerciseId,
    required this.orderIndex,
    required this.plannedSets,
    required this.plannedReps,
    this.plannedWeight,
    this.restSeconds,
    this.tempo,
    this.notes,
    this.exercise,
    required this.setTemplates,
  });

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      id: json['id'] as String,
      workoutSessionId: json['workoutSessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      orderIndex: json['orderIndex'] as int,
      plannedSets: json['plannedSets'] as int,
      plannedReps: json['plannedReps'] as int,
      plannedWeight: json['plannedWeight'] as num?,
      restSeconds: json['restSeconds'] as int?,
      tempo: json['tempo'] as String?,
      notes: json['notes'] as String?,
      exercise: json['exercise'] != null ? Exercise.fromJson(json['exercise'] as Map<String, dynamic>) : null,
      setTemplates: (json['setTemplates'] as List<dynamic>?)
              ?.map((e) => SetTemplate.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final String? slug;
  final String? description;
  final String? instructions;
  final String? image;

  Exercise({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    this.instructions,
    this.image,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String?,
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      image: json['image'] as String?,
    );
  }
}

class SetTemplate {
  final String id;
  final String sessionExerciseId;
  final int setNumber;
  final int plannedReps;
  final num? plannedWeight;
  final bool isWarmupSet;
  final String? notes;

  SetTemplate({
    required this.id,
    required this.sessionExerciseId,
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    required this.isWarmupSet,
    this.notes,
  });

  factory SetTemplate.fromJson(Map<String, dynamic> json) {
    return SetTemplate(
      id: json['id'] as String,
      sessionExerciseId: json['sessionExerciseId'] as String,
      setNumber: json['setNumber'] as int,
      plannedReps: json['plannedReps'] as int,
      plannedWeight: json['plannedWeight'] as num?,
      isWarmupSet: json['isWarmupSet'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }
}
