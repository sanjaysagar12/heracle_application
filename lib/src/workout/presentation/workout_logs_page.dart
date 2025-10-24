import 'package:flutter/material.dart';
import '../api/workout_logs_api.dart';
import '../domain/models/workout_log_model.dart';
import 'workout_progress_page.dart';

class WorkoutLogsPage extends StatefulWidget {
  const WorkoutLogsPage({Key? key}) : super(key: key);

  @override
  State<WorkoutLogsPage> createState() => _WorkoutLogsPageState();
}

class _WorkoutLogsPageState extends State<WorkoutLogsPage> {
  late Future<List<WorkoutLog>> _futureLogs;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _futureLogs = WorkoutLogsApi.fetchWorkoutLogs();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Colors.green;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return Icons.check_circle;
      case 'IN_PROGRESS':
        return Icons.play_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _viewLogDetails(WorkoutLog log) {
    // Navigate to workout progress page for any workout log
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutProgressPage(
          workoutLogId: log.workoutLogId,
          sessionName: log.sessionName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLogs,
          ),
        ],
      ),
      body: FutureBuilder<List<WorkoutLog>>(
        future: _futureLogs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final logs = snapshot.data ?? <WorkoutLog>[];
          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No workout logs found.'),
                  Text('Start a workout to see logs here!'),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final statusColor = _getStatusColor(log.status);
              final statusIcon = _getStatusIcon(log.status);
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Icon(statusIcon, color: Colors.white),
                  ),
                  title: Text(log.sessionName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${log.date}'),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Text(
                          log.status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _viewLogDetails(log),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
