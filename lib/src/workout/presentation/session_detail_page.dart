import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';

class SessionDetailPage extends StatelessWidget {
  final WorkoutSession session;

  const SessionDetailPage({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(session.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          // show lastWorkoutLogId prominently if present
          if (session.lastWorkoutLogId != null && session.lastWorkoutLogId!.isNotEmpty)
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('Last workout log'),
                subtitle: Text(session.lastWorkoutLogId!),
              ),
            ),
          if (session.notes != null && session.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(session.notes!, style: const TextStyle(fontSize: 14)),
            ),
          ...session.sessionExercises.map((se) {
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
