class WorkoutLog {
  final String workoutLogId;
  final String date;
  final String sessionName;
  final String status;

  WorkoutLog({
    required this.workoutLogId,
    required this.date,
    required this.sessionName,
    required this.status,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      workoutLogId: json['workoutLogId'] as String,
      date: json['date'] as String,
      sessionName: json['sessionName'] as String,
      status: json['status'] as String,
    );
  }
}
