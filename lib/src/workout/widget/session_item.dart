import 'package:flutter/material.dart';
import '../domain/models/session_model.dart';
import '../presentation/session_detail_page.dart';
import '../presentation/workout_progress_page.dart';
import '../api/workout_progress_api.dart';

class SessionItem extends StatelessWidget {
  final WorkoutSession session;

  const SessionItem({Key? key, required this.session}) : super(key: key);

  Future<void> _startWorkout(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await WorkoutProgressApi.startWorkout(session.id);
      final workoutLogId = response['workoutLogId'] as String;

      Navigator.of(context).pop(); // Close loading dialog

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WorkoutProgressPage(
            workoutLogId: workoutLogId,
            sessionName: session.name,
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start workout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(child: Text(session.name)),
                if (session.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (session.isPublic)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.public,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((session.description ?? '').isNotEmpty) Text(session.description!),
                if (session.lastWorkoutLogId != null && session.lastWorkoutLogId!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Last Log: ${session.lastWorkoutLogId!}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionDetailPage(session: session),
                ),
              );
            },
          ),
          // Start Workout Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startWorkout(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
