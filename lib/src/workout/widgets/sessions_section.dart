import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/session_repository.dart';
import '../presentation/tab/log_workout_tab.dart';

class SessionsSection extends StatefulWidget {
  final SessionRepository? repository;
  const SessionsSection({super.key, this.repository});

  @override
  State<SessionsSection> createState() => _SessionsSectionState();
}

class _SessionsSectionState extends State<SessionsSection> {
  late Future<List<Session>> _sessionsFuture;
  String _selectedFilter = 'All';
  List<String> _filters = ['All'];

  @override
  void initState() {
    super.initState();
    _loadFuture();
  }

  @override
  void didUpdateWidget(covariant SessionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadFuture();
    setState(() {});
  }

  void _loadFuture() {
    final repo = widget.repository ?? SessionRepository();
    _sessionsFuture = repo.getSessionsFromDb();
  }

  Future<void> _onRefresh() async {
    _loadFuture();
    await _sessionsFuture;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: FutureBuilder<List<Session>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          }

          final data = snapshot.data ?? [];
          final cats = <String>{};
          for (var s in data) cats.add(s.category);
          _filters = ['All', ...cats.toList()];
          if (!_filters.contains(_selectedFilter)) _selectedFilter = 'All';

          final sessions = _selectedFilter == 'All' ? data : data.where((s) => s.category == _selectedFilter).toList();

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Sessions',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final label = _filters[i];
                      final selected = label == _selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = label),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.black100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                color: selected ? AppColors.black : AppColors.white60,
                                fontSize: 14,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: sessions.map((s) => _buildSessionCard(s)).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(Session s) {
    final images = s.exercises.map((e) => (e['image']?.toString() ?? '')).where((i) => i.isNotEmpty).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.title,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.content,
                      style: const TextStyle(color: AppColors.white60, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz, color: AppColors.white60),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ...images.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: CircleAvatar(radius: 12, backgroundImage: NetworkImage(a)),
              )),
              if (images.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: CircleAvatar(radius: 12, backgroundColor: AppColors.greyDark, child: Icon(Icons.fitness_center, color: AppColors.white60, size: 14)),
                ),
              const SizedBox(width: 8),
              Text('${s.exercisesCount} exercises', style: const TextStyle(color: AppColors.white60)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final exercisesForLog = s.exercises.map((e) {
                  return <String, dynamic>{
                    'id': e['id']?.toString() ?? '',
                    'name': e['name']?.toString() ?? '',
                    'desc': '',
                    'image': e['image']?.toString() ?? '',
                    'sets': e['sets'],
                  };
                }).toList();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LogWorkoutTab(
                      mode: 'start',
                      exercises: exercisesForLog,
                      sessionId: s.id,
                      sessionName: s.title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Start Session',
                style: TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
