import 'package:flutter/material.dart';
import '../domain/session_repository_impl.dart';
import '../api/session_api.dart';
import '../widget/session_item.dart';
import '../domain/models/session_model.dart';
import '../presentation/create_session_page.dart';
import '../presentation/workout_logs_page.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({Key? key}) : super(key: key);

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final SessionRepositoryImpl _repo;
  late Future<List<WorkoutSession>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _repo = SessionRepositoryImpl(api: SessionApi());
    _refreshSessions();
  }

  void _refreshSessions() {
    setState(() {
      _futureSessions = _repo.getSessions();
    });
  }

  Future<void> _navigateToCreateSession() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CreateSessionPage(),
      ),
    );

    if (result == true) {
      _refreshSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).pushNamed('/workout-logs');
            },
            tooltip: 'Workout Logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSessions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateSession,
        child: const Icon(Icons.add),
        tooltip: 'Create New Session',
      ),
      body: FutureBuilder<List<WorkoutSession>>(
        future: _futureSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sessions = snapshot.data ?? <WorkoutSession>[];
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions found.'));
          }
          return ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return SessionItem(session: sessions[index]);
            },
          );
        },
      ),
    );
  }
}
