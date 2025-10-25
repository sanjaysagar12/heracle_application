class WorkoutPost {
  final String id;
  final User user;
  final String caption;
  final String? imageS3Key;
  final bool isPublic;
  final DateTime createdAt;
  final WorkoutSummary workoutSummary;
  final int likesCount;
  final int commentsCount;
  final bool isLikedByUser;

  WorkoutPost({
    required this.id,
    required this.user,
    required this.caption,
    this.imageS3Key,
    required this.isPublic,
    required this.createdAt,
    required this.workoutSummary,
    required this.likesCount,
    required this.commentsCount,
    required this.isLikedByUser,
  });

  factory WorkoutPost.fromJson(Map<String, dynamic> json) {
    return WorkoutPost(
      id: json['id'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      caption: json['caption'] as String,
      imageS3Key: json['imageS3Key'] as String?,
      isPublic: json['isPublic'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      workoutSummary: WorkoutSummary.fromJson(json['workoutSummary'] as Map<String, dynamic>),
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLikedByUser: json['isLikedByUser'] as bool? ?? false,
    );
  }
}

class User {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;

  User({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class WorkoutSummary {
  final String id;
  final String sessionName;
  final String? sessionDescription;
  final String status;
  final double totalTimeMin;
  final int totalVolume;
  final int totalSets;
  final int totalReps;
  final int? caloriesBurned;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<WorkoutExercise> exercises;

  WorkoutSummary({
    required this.id,
    required this.sessionName,
    this.sessionDescription,
    required this.status,
    required this.totalTimeMin,
    required this.totalVolume,
    required this.totalSets,
    required this.totalReps,
    this.caloriesBurned,
    required this.startedAt,
    this.endedAt,
    required this.exercises,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      id: json['id'] as String,
      sessionName: json['sessionName'] as String,
      sessionDescription: json['sessionDescription'] as String?,
      status: json['status'] as String,
      totalTimeMin: (json['totalTimeMin'] as num).toDouble(),
      totalVolume: (json['totalVolume'] as num).toInt(),
      totalSets: (json['totalSets'] as num).toInt(),
      totalReps: (json['totalReps'] as num).toInt(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class WorkoutExercise {
  final Exercise exercise;
  final int plannedSets;
  final int actualSets;
  final int actualReps;
  final int actualVolume;
  final double? averageWeight;
  final List<SetTemplate> setTemplates;

  WorkoutExercise({
    required this.exercise,
    required this.plannedSets,
    required this.actualSets,
    required this.actualReps,
    required this.actualVolume,
    this.averageWeight,
    required this.setTemplates,
  });

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      plannedSets: (json['plannedSets'] as num).toInt(),
      actualSets: (json['actualSets'] as num).toInt(),
      actualReps: (json['actualReps'] as num).toInt(),
      actualVolume: (json['actualVolume'] as num).toInt(),
      averageWeight: (json['averageWeight'] as num?)?.toDouble(),
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
  final List<String> muscleGroups;
  final String primaryMuscle;
  final String? image;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroups,
    required this.primaryMuscle,
    this.image,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      muscleGroups: (json['muscleGroups'] as List<dynamic>?)?.cast<String>() ?? [],
      primaryMuscle: json['primaryMuscle'] as String,
      image: json['image'] as String?,
    );
  }
}

class SetTemplate {
  final int setNumber;
  final int plannedReps;
  final double? plannedWeight;
  final bool isWarmupSet;

  SetTemplate({
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    required this.isWarmupSet,
  });

  factory SetTemplate.fromJson(Map<String, dynamic> json) {
    return SetTemplate(
      setNumber: (json['setNumber'] as num).toInt(),
      plannedReps: (json['plannedReps'] as num).toInt(),
      plannedWeight: (json['plannedWeight'] as num?)?.toDouble(),
      isWarmupSet: json['isWarmupSet'] as bool? ?? false,
    );
  }
}
