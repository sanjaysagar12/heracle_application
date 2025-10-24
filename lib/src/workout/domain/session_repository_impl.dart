import 'package:flutter/foundation.dart';
import '../api/session_api.dart';
import 'session_repository.dart';
import 'models/session_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  final SessionApi api;

  SessionRepositoryImpl({required this.api});

  @override
  Future<List<WorkoutSession>> getSessions() async {
    // simple pass-through; add caching/error handling as needed
    return compute((_) async => await SessionApi.fetchSessions(), null)
        .then((future) => future)
        .catchError((e) => throw e);
  }
}
