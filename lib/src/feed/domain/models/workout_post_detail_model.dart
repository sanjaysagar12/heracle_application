class WorkoutPostDetail {
  final String id;
  final User user;
  final String caption;
  final String? imageS3Key;
  final bool isPublic;
  final DateTime createdAt;
  final WorkoutDetails workoutDetails;
  final List<dynamic> likes;
  final List<dynamic> comments;
  final bool isLikedByUser;
  final PostStats stats;

  WorkoutPostDetail({
    required this.id,
    required this.user,
    required this.caption,
    this.imageS3Key,
    required this.isPublic,
    required this.createdAt,
    required this.workoutDetails,
    required this.likes,
    required this.comments,
    required this.isLikedByUser,
    required this.stats,
  });

  factory WorkoutPostDetail.fromJson(Map<String, dynamic> json) {
    return WorkoutPostDetail(
      id: json['id'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      caption: json['caption'] as String,
      imageS3Key: json['imageS3Key'] as String?,
      isPublic: json['isPublic'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      workoutDetails: WorkoutDetails.fromJson(json['workoutDetails'] as Map<String, dynamic>),
      likes: (json['likes'] as List<dynamic>?) ?? [],
      comments: (json['comments'] as List<dynamic>?) ?? [],
      isLikedByUser: json['isLikedByUser'] as bool? ?? false,
      stats: PostStats.fromJson(json['stats'] as Map<String, dynamic>),
    );
  }
}

class User {
  final String id;
  final String username;
  final String name;
  final String? avatarUrl;

  User({required this.id, required this.username, required this.name, this.avatarUrl});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class WorkoutDetails {
  final SessionInfo sessionInfo;
  final Completion completion;
  final Performance performance;
  final List<MuscleGroupBreakdown> muscleGroupBreakdown;
  final List<ExerciseDetail> exercises;

  WorkoutDetails({
    required this.sessionInfo,
    required this.completion,
    required this.performance,
    required this.muscleGroupBreakdown,
    required this.exercises,
  });

  factory WorkoutDetails.fromJson(Map<String, dynamic> json) {
    return WorkoutDetails(
      sessionInfo: SessionInfo.fromJson(json['sessionInfo'] as Map<String, dynamic>),
      completion: Completion.fromJson(json['completion'] as Map<String, dynamic>),
      performance: Performance.fromJson(json['performance'] as Map<String, dynamic>),
      muscleGroupBreakdown: (json['muscleGroupBreakdown'] as List<dynamic>?)
              ?.map((e) => MuscleGroupBreakdown.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      exercises: (json['exercises'] as List<dynamic>?)
              ?.map((e) => ExerciseDetail.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SessionInfo {
  final String id;
  final String name;
  final String? description;

  SessionInfo({required this.id, required this.name, this.description});

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
    );
  }
}

class Completion {
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int duration;
  final bool isCompleted;

  Completion({
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.isCompleted,
  });

  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      status: json['status'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null,
      duration: (json['duration'] as num).toInt(),
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class Performance {
  final int totalExercises;
  final int totalSets;
  final int totalReps;
  final int totalVolume;
  final double? averageRpe;
  final int? caloriesBurned;

  Performance({
    required this.totalExercises,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    this.averageRpe,
    this.caloriesBurned,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      totalExercises: (json['totalExercises'] as num).toInt(),
      totalSets: (json['totalSets'] as num).toInt(),
      totalReps: (json['totalReps'] as num).toInt(),
      totalVolume: (json['totalVolume'] as num).toInt(),
      averageRpe: (json['averageRpe'] as num?)?.toDouble(),
      caloriesBurned: (json['caloriesBurned'] as num?)?.toInt(),
    );
  }
}

class MuscleGroupBreakdown {
  final String muscleGroup;
  final int sets;
  final int percentage;

  MuscleGroupBreakdown({required this.muscleGroup, required this.sets, required this.percentage});

  factory MuscleGroupBreakdown.fromJson(Map<String, dynamic> json) {
    return MuscleGroupBreakdown(
      muscleGroup: json['muscleGroup'] as String,
      sets: (json['sets'] as num).toInt(),
      percentage: (json['percentage'] as num).toInt(),
    );
  }
}

class ExerciseDetail {
  final Exercise exercise;
  final ExercisePerformance performance;
  final List<SetDetail> sets;

  ExerciseDetail({required this.exercise, required this.performance, required this.sets});

  factory ExerciseDetail.fromJson(Map<String, dynamic> json) {
    return ExerciseDetail(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      performance: ExercisePerformance.fromJson(json['performance'] as Map<String, dynamic>),
      sets: (json['sets'] as List<dynamic>?)
              ?.map((e) => SetDetail.fromJson(e as Map<String, dynamic>))
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

class ExercisePerformance {
  final int totalSets;
  final int totalReps;
  final int totalVolume;
  final double? maxWeight;
  final double? averageRpe;

  ExercisePerformance({
    required this.totalSets,
    required this.totalReps,
    required this.totalVolume,
    this.maxWeight,
    this.averageRpe,
  });

  factory ExercisePerformance.fromJson(Map<String, dynamic> json) {
    return ExercisePerformance(
      totalSets: (json['totalSets'] as num).toInt(),
      totalReps: (json['totalReps'] as num).toInt(),
      totalVolume: (json['totalVolume'] as num).toInt(),
      maxWeight: (json['maxWeight'] as num?)?.toDouble(),
      averageRpe: (json['averageRpe'] as num?)?.toDouble(),
    );
  }
}

class SetDetail {
  final int setNumber;
  final double? weight;
  final int reps;
  final double? rpe;
  final int volume;
  final int? durationSec;
  final int? distance;
  final String? notes;

  SetDetail({
    required this.setNumber,
    this.weight,
    required this.reps,
    this.rpe,
    required this.volume,
    this.durationSec,
    this.distance,
    this.notes,
  });

  factory SetDetail.fromJson(Map<String, dynamic> json) {
    return SetDetail(
      setNumber: (json['setNumber'] as num).toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      reps: (json['reps'] as num).toInt(),
      rpe: (json['rpe'] as num?)?.toDouble(),
      volume: (json['volume'] as num).toInt(),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      distance: (json['distance'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }
}

class PostStats {
  final int likesCount;
  final int commentsCount;

  PostStats({required this.likesCount, required this.commentsCount});

  factory PostStats.fromJson(Map<String, dynamic> json) {
    return PostStats(
      likesCount: (json['likesCount'] as num).toInt(),
      commentsCount: (json['commentsCount'] as num).toInt(),
    );
  }
}
