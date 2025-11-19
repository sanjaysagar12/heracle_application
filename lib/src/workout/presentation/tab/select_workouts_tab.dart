import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SelectWorkoutsTab extends StatelessWidget {
  const SelectWorkoutsTab({super.key});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Choose workouts to include in your session',
                style: TextStyle(color: AppColors.white60)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _sampleWorkouts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _sampleWorkouts[index];
                  return ListTile(
                    tileColor: AppColors.black100,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(backgroundImage: NetworkImage(item['image']!)),
                    title: Text(item['name']!, style: const TextStyle(color: AppColors.pureWhite)),
                    subtitle: Text(item['desc']!, style: const TextStyle(color: AppColors.white60)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.white60),
                    onTap: () {
                      // implement selection behavior as needed
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<Map<String, String>> _sampleWorkouts = [
  {
    'name': 'Full Body Circuit',
    'desc': '45 min · Moderate',
    'image': 'https://images.unsplash.com/photo-1558611848-73f7eb4001d7?w=200',
  },
  {
    'name': 'Upper Body Strength',
    'desc': '30 min · Intense',
    'image': 'https://images.unsplash.com/photo-1554284126-0c3d1d1cc2a0?w=200',
  },
  {
    'name': 'Leg Day Blast',
    'desc': '40 min · Hard',
    'image': 'https://images.unsplash.com/photo-1507842217343-583bb7270b66?w=200',
  },
];
