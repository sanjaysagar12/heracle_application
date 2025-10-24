import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';
import 'add_exercise_to_session_page.dart';

class SessionDetailPage extends StatefulWidget {
  final WorkoutSession session;

  const SessionDetailPage({Key? key, required this.session}) : super(key: key);

  @override
  State<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends State<SessionDetailPage> {
  late WorkoutSession _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

  Future<void> _navigateToAddExercise() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddExerciseToSessionPage(session: _currentSession),
      ),
    );

    // If exercise was added successfully, you might want to refresh the session
    // For now, we'll just show a message - you can add refresh logic later
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise added! Refresh to see changes.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSession.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddExercise,
            tooltip: 'Add Exercise',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddExercise,
        child: const Icon(Icons.add),
        tooltip: 'Add Exercise to Session',
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // show lastWorkoutLogId prominently if present
          if (_currentSession.lastWorkoutLogId != null && _currentSession.lastWorkoutLogId!.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last workout log'),
                subtitle: Text(_currentSession.lastWorkoutLogId!),
              ),
            ),
          if (_currentSession.notes != null && _currentSession.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_currentSession.notes!, style: const TextStyle(fontSize: 14)),
            ),
          ..._currentSession.sessionExercises.map((se) {
            final exerciseName = se.exercise?.name ?? se.exerciseId;
            final exerciseSubtitle = StringBuffer()
              ..write('Sets: ${se.plannedSets} • Reps: ${se.plannedReps}')
              ..write(se.plannedWeight != null ? ' • Wt: ${se.plannedWeight}' : '')
              ..write(se.restSeconds != null ? ' • Rest: ${se.restSeconds}s' : '')
              ..write(se.tempo != null ? ' • Tempo: ${se.tempo}' : '');
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                title: Text(exerciseName),
                subtitle: Text(exerciseSubtitle.toString()),
                children: [
                  if ((se.notes ?? '').isNotEmpty)
                    ListTile(
                      title: const Text('Notes'),
                      subtitle: Text(se.notes!),
                    ),
                  if (se.setTemplates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Set Templates', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          ...se.setTemplates.map((st) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text('Set ${st.setNumber}'),
                                subtitle: Text('Reps: ${st.plannedReps}${st.plannedWeight != null ? ' • Wt: ${st.plannedWeight}' : ''}${st.isWarmupSet ? ' • Warmup' : ''}'),
                              )),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
