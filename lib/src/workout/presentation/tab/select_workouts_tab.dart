import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'log_workout_tab.dart';
import 'create_session_tab.dart';
import '../../data/exercise_repository.dart';

class SelectWorkoutsTab extends StatefulWidget {
  final String mode; // 'start' or 'create'
  const SelectWorkoutsTab({super.key, required this.mode});

  @override
  State<SelectWorkoutsTab> createState() => _SelectWorkoutsTabState();
}

class _SelectWorkoutsTabState extends State<SelectWorkoutsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'All';
  List<String> _filters = ['All'];
  List<Map<String, String>> _items = [];
  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  final Set<String> _selectedIds = {};

  List<Map<String, String>> get _filteredItems {
    var list = _items;
    if (_selectedFilter != 'All') {
      list = list.where((it) => it['category'] == _selectedFilter).toList();
    }
    if (_query.isNotEmpty) {
      list = list.where((it) => it['name']!.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    try {
      final data = await _exerciseRepository.getExercises();
      final cats = <String>{};
      for (var it in data) {
        final cat = it['category'] ?? 'Other';
        cats.add(cat);
      }
      setState(() {
        _items = data;
        _filters = ['All', ...cats.toList()];
        // keep selected filter 'All' by default
      });
    } catch (_) {
      // keep defaults on error
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id); else _selectedIds.add(id);
    });
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
        title: const Text('Select Workouts', style: TextStyle(color: AppColors.pureWhite)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: AppColors.pureWhite),
                  decoration: InputDecoration(
                    hintText: 'Search Workout...',
                    hintStyle: const TextStyle(color: AppColors.white60),
                    filled: true,
                    fillColor: AppColors.black100,
                    prefixIcon: const Icon(Icons.search, color: AppColors.white60),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                            child: Text(label, style: TextStyle(color: selected ? AppColors.black : AppColors.white60)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredItems.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.greyDark, height: 1),
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final id = item['id']!;
                final selected = _selectedIds.contains(id);
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(radius: 22, backgroundImage: NetworkImage(item['image']!)),
                  title: Text(item['name']!, style: const TextStyle(color: AppColors.pureWhite)),
                  subtitle: Text(item['desc']!, style: const TextStyle(color: AppColors.white60)),
                  trailing: GestureDetector(
                    onTap: () => _toggleSelection(id),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white40),
                      ),
                      child: Icon(selected ? Icons.check : Icons.add, color: selected ? AppColors.black : AppColors.white60, size: 20),
                    ),
                  ),
                  onTap: () => _toggleSelection(id),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _selectedIds.isEmpty ? null : () {
                final selectedItems = _items.where((it) => _selectedIds.contains(it['id'])).toList();
                if (widget.mode == 'create') {
                  // Navigate to CreateWorkoutTab
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateWorkoutTab(exercises: selectedItems)),
                  );
                } else {
                  // Navigate to LogWorkoutTab
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LogWorkoutTab(mode: widget.mode, exercises: selectedItems)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Add ${_selectedIds.length} Exercises', style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }
}
