import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/session_repository.dart';
import '../../storage/workout_session_storage.dart';
import 'select_workouts_tab.dart';

class CreateSessionTab extends StatefulWidget {
  final List<Map<String, String>>? exercises;
  final Session? sessionToEdit; // Optional session to edit

  const CreateSessionTab({
    super.key,
    this.exercises,
    this.sessionToEdit,
  }) : assert(exercises != null || sessionToEdit != null,
            'Either exercises or sessionToEdit must be provided');

  @override
  State<CreateSessionTab> createState() => _CreateSessionTabState();
}

class _SetLog {
  String kg;
  String reps;
  _SetLog({this.kg = '', this.reps = ''});
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

class _CreateSessionTabState extends State<CreateSessionTab> {
  late List<_ExerciseLog> _exerciseLogs;
  final SessionRepository _sessionRepository = SessionRepository();
  final TextEditingController _sessionNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  List<String> _existingCategories = [];
  bool _showCategorySuggestions = false;
  bool get _isEditMode => widget.sessionToEdit != null;

  @override
  void initState() {
    super.initState();
    _loadExistingCategories();

    if (_isEditMode) {
      // Initialize with existing session data
      final session = widget.sessionToEdit!;
      _sessionNameController.text = session.title;
      _categoryController.text = session.category;

      _exerciseLogs = session.exercises.map((e) {
        final existingSets = e['sets'] as List<dynamic>? ?? [];
        final sets = existingSets.isNotEmpty
            ? existingSets.map((s) => _SetLog(
                kg: s['kg']?.toString() ?? '',
                reps: s['reps']?.toString() ?? '',
              )).toList()
            : List.generate(3, (_) => _SetLog(kg: '', reps: ''));

        return _ExerciseLog(
          id: e['id']?.toString() ?? '',
          name: e['name']?.toString() ?? '',
          desc: e['desc']?.toString() ?? '',
          image: e['image']?.toString() ?? '',
          sets: sets,
        );
      }).toList();
    } else {
      // Initialize with new exercises
      _exerciseLogs = (widget.exercises ?? []).map((e) {
        return _ExerciseLog(
          id: e['id'] ?? '',
          name: e['name'] ?? '',
          desc: e['desc'] ?? '',
          image: e['image'] ?? '',
          sets: List.generate(3, (_) => _SetLog(kg: '', reps: '')), // start with 3 sets
        );
      }).toList();
    }
  }

  Future<void> _loadExistingCategories() async {
    try {
      final sessions = await WorkoutSessionStorage.instance.getAllSessions();
      final categories = <String>{};
      for (var session in sessions) {
        if (session.category.isNotEmpty) {
          categories.add(session.category);
        }
      }
      setState(() {
        _existingCategories = categories.toList()..sort();
      });
    } catch (e) {
      print('Failed to load existing categories: $e');
    }
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  int get _workoutCount => _exerciseLogs.length;

  void _addSet(_ExerciseLog ex) {
    setState(() {
      ex.sets.add(_SetLog(kg: '', reps: ''));
    });
  }

  void _removeSet(_ExerciseLog ex, int index) {
    setState(() {
      if (ex.sets.length > 1) ex.sets.removeAt(index);
    });
  }

  void _discardWorkout() {
    Navigator.pop(context);
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

  Future<void> _saveSession() async {
    final sessionName = _sessionNameController.text.trim();
    final category = _categoryController.text.trim();

    if (sessionName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a session name')));
      return;
    }

    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a category')));
      return;
    }

    // build Session from _exerciseLogs
    final exercises = _exerciseLogs.map((ex) {
      return {
        'id': ex.id,
        'name': ex.name,
        'desc': ex.desc,
        'image': ex.image,
        'sets': ex.sets.map((s) => {'kg': int.tryParse(s.kg) ?? 0, 'reps': int.tryParse(s.reps) ?? 0}).toList(),
      };
    }).toList();

    final session = Session(
      id: _isEditMode ? widget.sessionToEdit!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: sessionName,
      content: _isEditMode ? widget.sessionToEdit!.content : 'Created from in-app workout',
      category: category,
      exercisesCount: exercises.length,
      exercises: exercises,
    );

    try {
      if (_isEditMode) {
        await _sessionRepository.updateSession(session);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session updated successfully')));
        Navigator.pop(context, true); // Return to previous screen with success indicator
      } else {
        await _sessionRepository.saveSessionToDb(session);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session created')));
        // Pop both CreateSessionTab and SelectWorkoutsTab to return to WorkoutPage
        Navigator.pop(context, true); // pop CreateSessionTab
        Navigator.pop(context, true); // pop SelectWorkoutsTab
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_isEditMode ? 'Update' : 'Save'} failed: $e')));
    }
  }

  Future<void> _handleDeleteExercise(_ExerciseLog exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black100,
        title: const Text(
          'Delete Exercise',
          style: TextStyle(color: AppColors.pureWhite),
        ),
        content: Text(
          'Are you sure you want to remove "${exercise.name}" from this session?',
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
      setState(() {
        _exerciseLogs.removeWhere((ex) => ex.id == exercise.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed "${exercise.name}" from session')),
      );
    }
  }

  Future<void> _handleReplaceExercise(_ExerciseLog exercise) async {
    final result = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectWorkoutsTab(mode: 'add'),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final selectedExercise = result.first;
      setState(() {
        final index = _exerciseLogs.indexWhere((ex) => ex.id == exercise.id);
        if (index != -1) {
          _exerciseLogs[index] = _ExerciseLog(
            id: selectedExercise['id'] ?? '',
            name: selectedExercise['name'] ?? '',
            desc: selectedExercise['desc'] ?? '',
            image: selectedExercise['image'] ?? '',
            sets: List.generate(3, (_) => _SetLog(kg: '', reps: '')),
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Replaced with "${selectedExercise['name']}"')),
      );
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
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_isEditMode ? 'Edit Session' : 'Create Session', style: const TextStyle(color: AppColors.pureWhite)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Session Name Input
            TextField(
              controller: _sessionNameController,
              style: const TextStyle(color: AppColors.pureWhite),
              decoration: InputDecoration(
                labelText: 'Session Name',
                labelStyle: const TextStyle(color: AppColors.white60),
                hintText: 'e.g., Morning Workout',
                hintStyle: const TextStyle(color: AppColors.white60),
                filled: true,
                fillColor: AppColors.black100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            // Category Input with suggestions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _categoryController,
                  style: const TextStyle(color: AppColors.pureWhite),
                  onTap: () {
                    setState(() {
                      _showCategorySuggestions = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _showCategorySuggestions = value.isEmpty && _existingCategories.isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: AppColors.white60),
                    hintText: 'e.g., Strength, Cardio, Custom',
                    hintStyle: const TextStyle(color: AppColors.white60),
                    filled: true,
                    fillColor: AppColors.black100,
                    suffixIcon: _existingCategories.isNotEmpty
                        ? Icon(
                            _showCategorySuggestions ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: AppColors.white60,
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                if (_showCategorySuggestions && _existingCategories.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.black100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.greyDark),
                    ),
                    constraints: const BoxConstraints(maxHeight: 150),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _existingCategories.length,
                      itemBuilder: (context, index) {
                        final category = _existingCategories[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            category,
                            style: const TextStyle(color: AppColors.pureWhite),
                          ),
                          onTap: () {
                            setState(() {
                              _categoryController.text = category;
                              _showCategorySuggestions = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Workout count chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fitness_center, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('$_workoutCount Exercises', style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Exercise list
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                setState(() {
                  final item = _exerciseLogs.removeAt(oldIndex);
                  _exerciseLogs.insert(newIndex, item);
                });
              },
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
                for (final ex in _exerciseLogs)
                  Container(
                    key: ValueKey(ex.id), // Ensure each item has a unique key
                    margin: const EdgeInsets.only(bottom: 12),
                    child: _buildExerciseCard(ex),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Save Session button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveSession,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(_isEditMode ? 'Save Session' : 'Create Session', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Add Workout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _addWorkout,
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text('Add Workout', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black100,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Discard Workout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _discardWorkout,
                child: const Text('Discard Workout', style: TextStyle(color: Colors.red, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black100,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
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
              const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.drag_indicator, color: AppColors.white60, size: 20),
              ),
              CircleAvatar(backgroundImage: NetworkImage(ex.image), radius: 20, backgroundColor: AppColors.greyDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ex.name, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(ex.desc, style: const TextStyle(color: AppColors.white60, fontSize: 12)),
                ]),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'replace':
                      _handleReplaceExercise(ex);
                      break;
                    case 'delete':
                      _handleDeleteExercise(ex);
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
                    value: 'replace',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, color: AppColors.white60, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Replace Exercise',
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
                          'Delete Exercise',
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
                                hintText: '0',
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
                                hintText: '0',
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
            child: OutlinedButton.icon(
              onPressed: () => _addSet(ex),
              icon: const Icon(Icons.add, color: AppColors.pureWhite, size: 20),
              label: const Text('Add Set', style: TextStyle(color: AppColors.pureWhite)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.white40),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
