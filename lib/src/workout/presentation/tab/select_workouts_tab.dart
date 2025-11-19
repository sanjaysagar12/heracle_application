import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'log_workout_tab.dart';

class SelectWorkoutsTab extends StatefulWidget {
  final String mode; // 'start' or 'create'
  const SelectWorkoutsTab({super.key, required this.mode});

  @override
  State<SelectWorkoutsTab> createState() => _SelectWorkoutsTabState();
}

class _SelectWorkoutsTabState extends State<SelectWorkoutsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'Functional';
  final List<String> _filters = ['Functional', 'Biceps', 'Triceps', 'Chest', 'Legs', 'Other'];

  final List<Map<String, String>> _items = [
    {'id': 'w1','name': 'Bench Press (Barbell)','desc':'Chest','image':'https://images.unsplash.com/photo-1558611848-73f7eb4001d7?w=200','category':'Chest'},
    {'id': 'w2','name': 'Incline Dumbbell Press','desc':'Chest','image':'https://images.unsplash.com/photo-1554284126-0c3d1d1cc2a0?w=200','category':'Chest'},
    {'id': 'w3','name': 'Barbell Curl','desc':'Biceps','image':'https://images.unsplash.com/photo-1526403222633-3c9b7f3c6f6f?w=200','category':'Biceps'},
    {'id': 'w4','name': 'Tricep Dip','desc':'Triceps','image':'https://images.unsplash.com/photo-1517976487492-5750f3195933?w=200','category':'Triceps'},
    {'id': 'w5','name': 'Squat','desc':'Legs','image':'https://images.unsplash.com/photo-1434682881908-b43d0467b798?w=200','category':'Legs'},
    {'id': 'w6','name': 'Push Up','desc':'Functional','image':'https://images.unsplash.com/photo-1594737625785-0a6d7b5b6c1a?w=200','category':'Functional'},
    // ...add more as needed...
  ];

  final Set<String> _selectedIds = {};

  List<Map<String, String>> get _filteredItems {
    var list = _items.where((it) => it['category'] == _selectedFilter).toList();
    if (_query.isNotEmpty) {
      list = list.where((it) => it['name']!.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return list;
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LogWorkoutTab(mode: widget.mode, exercises: selectedItems)),
                );
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
