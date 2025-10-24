const String apiBase = 'http://localhost:3000';
const String devTokenPath = '/api/auth/dev/token';
const String devTokenUrl = '$apiBase$devTokenPath';
const String sessionsPath = '/api/workout/session';
const String sessionsUrl = '$apiBase$sessionsPath';

const String exercisesPath = '/api/workout/exercises';
const String exercisesUrl = '$apiBase$exercisesPath';

String sessionExercisesPath(String sessionId) => '/api/workout/session/$sessionId/exercises';
String sessionExercisesUrl(String sessionId) => '$apiBase${sessionExercisesPath(sessionId)}';

String workoutStartPath(String sessionId) => '/api/workout/progress/$sessionId/start';
String workoutStartUrl(String sessionId) => '$apiBase${workoutStartPath(sessionId)}';

String workoutProgressPath(String logId) => '/api/workout/progress/log/$logId';
String workoutProgressUrl(String logId) => '$apiBase${workoutProgressPath(logId)}';

String updateExerciseProgressPath(String logId, String exerciseId) => '/api/workout/progress/log/$logId/exercise/$exerciseId';
String updateExerciseProgressUrl(String logId, String exerciseId) => '$apiBase${updateExerciseProgressPath(logId, exerciseId)}';

String completeWorkoutPath(String logId) => '/api/workout/progress/log/$logId/complete';
String completeWorkoutUrl(String logId) => '$apiBase${completeWorkoutPath(logId)}';
