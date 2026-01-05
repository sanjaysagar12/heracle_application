import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    final isAddMode = widget.mode == 'add';
    final buttonLabel = isAddMode
        ? 'Add ${_selectedIds.length} Exercises'
        : 'Add ${_selectedIds.length} Exercises';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Workouts', style: TextStyle(color: AppColors.pureWhite)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
                      suffixIcon: const Icon(Icons.search, color: AppColors.white60),
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
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredItems[index];
                final id = item['id']!;
                final selected = _selectedIds.contains(id);
                return Column(
                  children: [
                    ListTile(
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
                    ),
                    if (index < _filteredItems.length - 1)
                      const Divider(color: AppColors.greyDark, height: 1),
                  ],
                );
              },
              childCount: _filteredItems.length,
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: _selectedIds.isEmpty ? 16 : 96)),
        ],
      ),
      // show floating action button only when at least one item is selected
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: _selectedIds.isEmpty ? const Offset(0, 1.5) : Offset.zero,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          opacity: _selectedIds.isEmpty ? 0.0 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FloatingActionButton.extended(
                onPressed: _selectedIds.isEmpty ? null : () async {
                  final selectedItems = _items.where((it) => _selectedIds.contains(it['id'])).toList();
                  
                  // if mode is 'add', return selected exercises to caller
                  if (isAddMode) {
                    Navigator.pop(context, selectedItems);
                    return;
                  }

                  if (widget.mode == 'create') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CreateSessionTab(exercises: selectedItems)),
                    );
                    
                    // If session was created successfully, return to workout page
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LogWorkoutTab(
                          mode: widget.mode,
                          exercises: selectedItems.map((e) => <String, dynamic>{
                            'id': e['id'],
                            'name': e['name'],
                            'desc': e['desc'],
                            'image': e['image'],
                          }).toList(),
                        ),
                      ),
                    );
                  }
                },
                backgroundColor: AppColors.primary,
                label: Text(buttonLabel, style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w700)),
                icon: const SizedBox.shrink(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 4,
                isExtended: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
