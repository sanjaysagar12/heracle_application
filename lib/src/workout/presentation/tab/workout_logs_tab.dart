import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart'; // Added
import '../../../../core/theme/app_colors.dart';
import '../../data/session_repository.dart';
import '../workout_log_detail_page.dart'; // Added

class WorkoutLogsTab extends StatefulWidget {
  const WorkoutLogsTab({super.key});

  @override
  State<WorkoutLogsTab> createState() => _WorkoutLogsTabState();
}

class _WorkoutLogsTabState extends State<WorkoutLogsTab> {
  final SessionRepository _sessionRepository = SessionRepository();
  late Future<List<WorkoutLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logsFuture = _sessionRepository.getWorkoutLogsFromDb();
  }

  Future<void> _onRefresh() async {
    _loadLogs();
    await _logsFuture;
    setState(() {});
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Workout History', style: TextStyle(color: AppColors.pureWhite)),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: FutureBuilder<List<WorkoutLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading logs: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.white60),
                ),
              );
            }

            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: AppColors.white60),
                    const SizedBox(height: 16),
                    const Text(
                      'No workout logs yet',
                      style: TextStyle(color: AppColors.white60, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete a workout to see your history',
                      style: TextStyle(color: AppColors.white60, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            // Group logs by date
            final grouped = <String, List<WorkoutLog>>{};
            for (var log in logs) {
              final date = log.completedAt.toLocal();
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final yesterday = today.subtract(const Duration(days: 1));
              final dateOnly = DateTime(date.year, date.month, date.day);

              String header;
              if (dateOnly == today) {
                header = 'Today';
              } else if (dateOnly == yesterday) {
                header = 'Yesterday';
              } else {
                header = DateFormat('EEE, MMM dd').format(date);
              }

              if (!grouped.containsKey(header)) {
                grouped[header] = [];
              }
              grouped[header]!.add(log);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final header = grouped.keys.elementAt(index);
                final items = grouped[header]!;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildLogCard(log),
                    )).toList(),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(WorkoutLog log) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutLogDetailPage(log: log),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(log.completedAt),
                      style: const TextStyle(color: AppColors.white60, fontSize: 12),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios, color: AppColors.white60, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.white10, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.access_time, _formatDuration(log.duration), 'Duration'),
                _buildStatItem(Icons.monitor_weight_outlined, '${log.totalVolume}kg', 'Volume'),
                _buildStatItem(Icons.fitness_center, '${log.exercisesCount}', 'Exercises'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.white60, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
