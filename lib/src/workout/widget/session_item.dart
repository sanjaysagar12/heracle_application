import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';

class SessionItem extends StatelessWidget {
  final WorkoutSession session;

  const SessionItem({Key? key, required this.session}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(session.name),
      subtitle: Text(session.description ?? ''),
      children: session.sessionExercises.map((se) {
        final exerciseName = se.exercise?.name ?? se.exerciseId;
        return ListTile(
          title: Text(exerciseName),
          subtitle: Text('Sets: ${se.plannedSets} • Reps: ${se.plannedReps}'),
          trailing: Text(se.tempo ?? ''),
        );
      }).toList(),
    );
  }
}
