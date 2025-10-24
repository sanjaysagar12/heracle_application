import 'package:flutter/material.dart';
import '../domain/session_repository_impl.dart';
import '../api/session_api.dart';
import '../widget/session_item.dart';
import '../domain/models/session_model.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({Key? key}) : super(key: key);

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late final SessionRepositoryImpl _repo;
  late final Future<List<WorkoutSession>> _futureSessions;

  @override
  void initState() {
    super.initState();
    _repo = SessionRepositoryImpl(api: SessionApi());
    _futureSessions = _repo.getSessions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions')),
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
