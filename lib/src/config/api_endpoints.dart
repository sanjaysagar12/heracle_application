const String apiBase = 'https://api-heracle-backend.portos.cloud';
const String devTokenPath = '/api/auth/google/token';
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

String postWorkoutPath(String logId) => '/api/workout/progress/log/$logId/post';
String postWorkoutUrl(String logId) => '$apiBase${postWorkoutPath(logId)}';

const String workoutLogsPath = '/api/workout/progress/my-logs';
const String workoutLogsUrl = '$apiBase$workoutLogsPath';

const String workoutPostsPath = '/api/feed/workout-posts';
const String workoutPostsUrl = '$apiBase$workoutPostsPath';

String workoutPostImagePath(String postId) => '/api/workout/progress/post/$postId/image';
String workoutPostImageUrl(String postId) => '$apiBase${workoutPostImagePath(postId)}';

String workoutPostDetailPath(String postId) => '/api/feed/workout-posts/$postId';
String workoutPostDetailUrl(String postId) => '$apiBase${workoutPostDetailPath(postId)}';
