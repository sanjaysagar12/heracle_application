import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class LogWorkoutTab extends StatelessWidget {
  final String mode; // 'start' or 'create'
  final List<Map<String, String>> exercises;

  const LogWorkoutTab({super.key, required this.mode, required this.exercises});

  @override
  Widget build(BuildContext context) {
    final title = mode == 'create' ? 'Create Workout' : 'Log Workout';
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: const TextStyle(color: AppColors.pureWhite)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('${exercises.length} exercises selected', style: const TextStyle(color: AppColors.white60)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.greyDark),
                itemBuilder: (context, i) {
                  final item = exercises[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: NetworkImage(item['image']!)),
                    title: Text(item['name']!, style: const TextStyle(color: AppColors.pureWhite)),
                    subtitle: Text(item['desc']!, style: const TextStyle(color: AppColors.white60)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // finalize and go back (or start session)
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(mode == 'create' ? 'Create & Add to Plan' : 'Start Session', style: const TextStyle(color: AppColors.black, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
