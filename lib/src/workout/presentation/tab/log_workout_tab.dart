import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/session_repository.dart';
import 'select_workouts_tab.dart';

class LogWorkoutTab extends StatefulWidget {
  final String mode; // 'start' or 'create'
  final List<Map<String, dynamic>> exercises;
  final String? sessionId; // optional: if starting from saved session
  final String? sessionName; // optional: session name

  const LogWorkoutTab({
    super.key,
    required this.mode,
    required this.exercises,
    this.sessionId,
    this.sessionName,
  });

  @override
  State<LogWorkoutTab> createState() => _LogWorkoutTabState();
}

class _SetLog {
  String kg;
  String reps;
  bool completed;
  String? placeholderKg; // placeholder from saved session
  String? placeholderReps; // placeholder from saved session
  _SetLog({
    this.kg = '',
    this.reps = '',
    this.completed = false,
    this.placeholderKg,
    this.placeholderReps,
  });
}

class _ExerciseLog {
  final String id;
  final String name;
  final String desc;
  final String image;
  List<_SetLog> sets;
  _ExerciseLog({
    required this.id,
    required this.name,
    required this.desc,
    required this.image,
    required this.sets,
  });
}

class _LogWorkoutTabState extends State<LogWorkoutTab> {
  late List<_ExerciseLog> _exerciseLogs;
  late DateTime _startTime;
  final SessionRepository _sessionRepository = SessionRepository();

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _exerciseLogs = widget.exercises.map((e) {
      // if exercise has saved sets, use them; otherwise create 3 empty sets
      final savedSets = e['sets'];
      List<_SetLog> sets;
      if (savedSets != null && savedSets is List && savedSets.isNotEmpty) {
        sets = savedSets.map((s) {
          final sMap = s as Map<String, dynamic>;
          final savedKg = sMap['kg']?.toString() ?? '';
          final savedReps = sMap['reps']?.toString() ?? '';
          return _SetLog(
            kg: '', // keep empty - user will enter new values
            reps: '', // keep empty
            placeholderKg: savedKg.isNotEmpty && savedKg != '0' ? savedKg : null,
            placeholderReps: savedReps.isNotEmpty && savedReps != '0' ? savedReps : null,
          );
        }).toList();
      } else {
        sets = List.generate(3, (_) => _SetLog(kg: '', reps: ''));
      }
      return _ExerciseLog(
        id: e['id'] ?? '',
        name: e['name'] ?? '',
        desc: e['desc'] ?? '',
        image: e['image'] ?? '',
        sets: sets,
      );
    }).toList();
  }

  int get _totalSetCount => _exerciseLogs.fold(0, (s, ex) => s + ex.sets.length);

  int get _workoutCount => _exerciseLogs.length;

  int get _totalVolume {
    var total = 0;
    for (var ex in _exerciseLogs) {
      for (var st in ex.sets) {
        final kg = int.tryParse(st.kg) ?? 0;
        final reps = int.tryParse(st.reps) ?? 0;
        total += kg * reps;
      }
    }
    return total;
  }

  String get _durationStr {
    final dur = DateTime.now().difference(_startTime);
    if (dur.inHours > 0) return '${dur.inHours}h ${dur.inMinutes % 60}m';
    if (dur.inMinutes > 0) return '${dur.inMinutes}m ${dur.inSeconds % 60}s';
    return '${dur.inSeconds}s';
  }

  void _addSet(_ExerciseLog ex) {
    setState(() {
      ex.sets.add(_SetLog(kg: '', reps: ''));
    });
  }

  void _toggleComplete(_SetLog set) {
    setState(() {
      set.completed = !set.completed;
    });
  }

  void _removeSet(_ExerciseLog ex, int index) {
    setState(() {
      if (ex.sets.length > 1) ex.sets.removeAt(index);
    });
  }

  void _discardWorkout() {
    setState(() {
      // reset all sets to default
      for (var ex in _exerciseLogs) {
        ex.sets = [for (var i = 0; i < 3; i++) _SetLog(kg: '', reps: '')];
      }
      _startTime = DateTime.now();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout discarded')));
  }

  Future<void> _addWorkout() async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectWorkoutsTab(mode: 'add'),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        for (var ex in result) {
          _exerciseLogs.add(_ExerciseLog(
            id: ex['id'] ?? '',
            name: ex['name'] ?? '',
            desc: ex['desc'] ?? '',
            image: ex['image'] ?? '',
            sets: List.generate(3, (_) => _SetLog(kg: '', reps: '')),
          ));
        }
      });
    }
  }

  // Simplified: only finish session logic
  Future<void> _finishSession() async {
    // save completed workout to database
    try {
      final sessionId = widget.sessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
      final exercises = _exerciseLogs.map((ex) {
        return {
          'id': ex.id,
          'name': ex.name,
          'image': ex.image,
          'sets': ex.sets.map((s) => {'kg': int.tryParse(s.kg) ?? 0, 'reps': int.tryParse(s.reps) ?? 0}).toList(),
        };
      }).toList();

      final session = Session(
        id: sessionId,
        title: widget.sessionName ?? 'Workout ${DateTime.now().toIso8601String().split('T').first}',
        content: 'Completed workout session',
        category: 'Workout History',
        exercisesCount: exercises.length,
        exercises: exercises,
      );

      await _sessionRepository.saveSessionToDb(session);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session finished & saved')));
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.sessionName ?? 'Log Workout', style: const TextStyle(color: AppColors.pureWhite)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top summary chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _summaryChip(_durationStr, 'Duration'),
                  const SizedBox(width: 8),
                  _summaryChip('$_totalVolume kg', 'Volume'),
                  const SizedBox(width: 8),
                  _summaryChip('$_totalSetCount', 'Set Count'),
                  const SizedBox(width: 8),
                  _summaryChip('$_workoutCount', 'Workouts'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Exercise list
            Expanded(
              child: ListView.separated(
                itemCount: _exerciseLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, exIndex) {
                  final ex = _exerciseLogs[exIndex];
                  return _buildExerciseCard(ex);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Finish Session button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _finishSession,
                icon: const Icon(Icons.flag, color: Colors.black),
                label: const Text('Finish Session', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Add Workout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addWorkout,
                icon: const Icon(Icons.add, color: AppColors.pureWhite),
                label: const Text('Add Workout', style: TextStyle(color: AppColors.pureWhite)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.white40),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Discard Workout (danger)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _discardWorkout,
                child: const Text('Discard Workout', style: TextStyle(color: Colors.red)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(_ExerciseLog ex) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // header
          Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(ex.image), radius: 20, backgroundColor: AppColors.greyDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(ex.desc, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
                ]),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz, color: AppColors.white60)),
            ],
          ),
          const SizedBox(height: 12),
          // sets
          Column(
            children: List.generate(ex.sets.length, (si) {
              final set = ex.sets[si];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text('Set ${si + 1}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Kg', style: TextStyle(color: AppColors.white60, fontSize: 12)),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: set.placeholderKg ?? '',
                                hintStyle: const TextStyle(color: AppColors.white60),
                                filled: true,
                                fillColor: AppColors.greyDark,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              style: const TextStyle(color: AppColors.pureWhite),
                              onChanged: (v) => setState(() => set.kg = v),
                              controller: TextEditingController(text: set.kg)..selection = TextSelection.fromPosition(TextPosition(offset: set.kg.length)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Reps', style: TextStyle(color: AppColors.white60, fontSize: 12)),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: set.placeholderReps ?? '',
                                hintStyle: const TextStyle(color: AppColors.white60),
                                filled: true,
                                fillColor: AppColors.greyDark,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                              ),
                              style: const TextStyle(color: AppColors.pureWhite),
                              onChanged: (v) => setState(() => set.reps = v),
                              controller: TextEditingController(text: set.reps)..selection = TextSelection.fromPosition(TextPosition(offset: set.reps.length)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _removeSet(ex, si),
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          // add set
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _addSet(ex),
              child: const Text('+ Add Set', style: TextStyle(color: AppColors.pureWhite)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.white40),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
