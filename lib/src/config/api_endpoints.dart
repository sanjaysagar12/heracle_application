const String apiBase = 'http://localhost:3000';
const String devTokenPath = '/api/auth/dev/token';
const String devTokenUrl = '$apiBase$devTokenPath';
const String sessionsPath = '/api/workout/session';
const String sessionsUrl = '$apiBase$sessionsPath';

const String exercisesPath = '/api/workout/exercises';
const String exercisesUrl = '$apiBase$exercisesPath';

String sessionExercisesPath(String sessionId) => '/api/workout/session/$sessionId/exercises';
String sessionExercisesUrl(String sessionId) => '$apiBase${sessionExercisesPath(sessionId)}';
