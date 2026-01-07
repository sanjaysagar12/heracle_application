import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../data/session_repository.dart';
import '../presentation/tab/log_workout_tab.dart';
import '../presentation/tab/create_session_tab.dart';
import '../presentation/tab/workout_logs_tab.dart'; // Added
import '../presentation/view_session_page.dart';

class SessionsSection extends StatefulWidget {
  final SessionRepository? repository;
  final List<Session>? sessions; // Allow passing sessions directly
  final bool isViewOnly; // Add this

  const SessionsSection({
    super.key, 
    this.repository,
    this.sessions,
    this.isViewOnly = false, // Default to false
  });

  @override
  State<SessionsSection> createState() => _SessionsSectionState();
}

class _SessionsSectionState extends State<SessionsSection> {
  List<Session> _sessions = [];
  bool _isLoading = true;
  bool _isReordering = false;
  String _selectedFilter = 'All';
  List<String> _filters = ['All'];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(covariant SessionsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions != oldWidget.sessions) {
      _loadSessions();
    }
  }

  Future<void> _loadSessions() async {
    if (widget.sessions != null) {
      if (mounted) {
        setState(() {
          _sessions = widget.sessions!;
          _isLoading = false;
        });
      }
      return;
    }

    final repo = widget.repository ?? SessionRepository();
    try {
      final sessions = await repo.getSessionsFromDb();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadSessions();
  }

  void _onReorder(int oldIndex, int newIndex) async {
    // Reordering should ideally be disabled in viewOnly mode, 
    // but if it were enabled, it would modify local list. 
    // For now, if viewOnly is true, we simply don't persist it or we disable drag handle.
    // However, if displayed via ReorderableListView, dragging is allowed by logic.
    // The parent widget controls whether to update the DB.
    
    if (widget.isViewOnly) return; 

    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Session item = _sessions.removeAt(oldIndex);
      _sessions.insert(newIndex, item);
    });

    // Update database
    final repo = widget.repository ?? SessionRepository();
    await repo.updateSessionOrder(_sessions);
  }

  Future<void> _handleEditSession(Session session) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSessionTab(sessionToEdit: session),
      ),
    );
    
    if (result == true) {
      // Refresh the sessions list after successful edit
      _loadSessions();
    }
  }

  Future<void> _handleDeleteSession(Session session) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black100,
        title: const Text(
          'Delete Session',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This action cannot be undone.',
          style: const TextStyle(color: AppColors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.white60),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = widget.repository ?? SessionRepository();
        await repo.deleteSession(session.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${session.title}"')),
          );

          // Refresh the sessions list
          _loadSessions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete session: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      child: _isLoading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          : Builder(
              builder: (context) {
                final cats = <String>{};
                for (var s in _sessions) cats.addAll(s.categories);
                _filters = ['All', ...cats.toList()];
                if (!_filters.contains(_selectedFilter)) _selectedFilter = 'All';

                final displayedSessions = _selectedFilter == 'All'
                    ? _sessions
                    : _sessions.where((s) => s.categories.contains(_selectedFilter)).toList();

                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Your Sessions',
                            style: TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedFilter == 'All' && _sessions.length > 1 && !widget.isViewOnly) ...[
                             const SizedBox(width: 8),
                             if (_isReordering)
                               TextButton(
                                 onPressed: () => setState(() => _isReordering = false),
                                 child: const Text('Done', style: TextStyle(color: AppColors.primary)),
                               ),
                          ],
                          const Spacer(), // Push to right
                          IconButton(
                            icon: const Icon(Icons.history, color: AppColors.primary),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WorkoutLogsTab(),
                                ),
                              );
                            },
                          ),
                        ],
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
                      // If reordering is allowed and active, use ReorderableListView, otherwise just a column
                      if (!widget.isViewOnly && _selectedFilter == 'All' && _isReordering)
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          onReorder: _onReorder,
                          onReorderStart: (index) {
                            HapticFeedback.heavyImpact();
                          },
                          proxyDecorator: (child, index, animation) {
                            return AnimatedBuilder(
                              animation: animation,
                              builder: (BuildContext context, Widget? child) {
                                final double animValue = Curves.easeInOut.transform(animation.value);
                                final double scale = 1.0 + (0.05 * animValue);
                                return Transform.scale(
                                  scale: scale,
                                  child: Material(
                                    color: Colors.transparent,
                                    elevation: 8,
                                    shadowColor: Colors.black45,
                                    child: child,
                                  ),
                                );
                              },
                              child: child,
                            );
                          },
                          children: [
                            for (final s in displayedSessions)
                              Container(
                                key: ValueKey(s.id),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: _buildSessionCard(s, isReorderable: true),
                              ),
                          ],
                        )
                      else
                        Column(
                          children: displayedSessions.map((s) => _buildSessionCard(s, isReorderable: false)).toList(),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSessionCard(Session s, {bool isReorderable = false}) {
    final images = s.exercises.map((e) => (e['image']?.toString() ?? '')).where((i) => i.isNotEmpty).toList();
    
    return Container(
      // margin handled by parent in ReorderableListView, or here if Column
      margin: (!isReorderable && widget.isViewOnly) ? const EdgeInsets.only(bottom: 12) : null,
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
              if (isReorderable && !widget.isViewOnly)
                const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.drag_indicator, color: AppColors.white60, size: 20),
                ),
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
              if (!widget.isViewOnly)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'reorder':
                        setState(() => _isReordering = true);
                        break;
                      case 'edit':
                        _handleEditSession(s);
                        break;
                      case 'delete':
                        _handleDeleteSession(s);
                        break;
                    }
                  },
                  color: AppColors.black100,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.greyDark),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reorder',
                      child: Row(
                        children: [
                          Icon(Icons.swap_vert, color: AppColors.white60, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Reorder',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: AppColors.white60, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Edit Session',
                            style: TextStyle(color: AppColors.pureWhite),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'Delete Session',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz, color: AppColors.white60),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (images.isNotEmpty)
                SizedBox(
                  width: 70,
                  height: 28,
                  child: Stack(
                    children: images.take(3).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final imageUrl = entry.value;
                      return Positioned(
                        left: index * 20.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.black100, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(imageUrl),
                            backgroundColor: AppColors.greyDark,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (images.isEmpty)
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.black100, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.greyDark,
                    child: Icon(Icons.fitness_center, color: AppColors.white60, size: 14),
                  ),
                ),
              const SizedBox(width: 8),
              Text('${s.exercisesCount} exercises', style: const TextStyle(color: AppColors.white60)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: widget.isViewOnly
                ? OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ViewSessionPage(session: s),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'View Session',
                      style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  )
                : ElevatedButton(
                    onPressed: () {
                      final exercisesForLog = s.exercises.map((e) {
                        return <String, dynamic>{
                          'id': e['id']?.toString() ?? '',
                          'name': e['name']?.toString() ?? '',
                          'desc': e['desc']?.toString() ?? '',
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
                      shape: const StadiumBorder(),
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
