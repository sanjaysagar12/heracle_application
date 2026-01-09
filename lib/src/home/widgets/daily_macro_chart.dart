import 'package:flutter/material.dart';
import '../../workout/widgets/pie_chart_widget.dart';
import '../../../core/theme/app_colors.dart';

class DailyMacroChart extends StatelessWidget {
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  const DailyMacroChart({
    super.key,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  @override
  Widget build(BuildContext context) {
    // If no data, return empty container or SizedBox.shrink()
    if (protein == 0 && carbs == 0 && fat == 0 && fiber == 0) {
      return const SizedBox.shrink();
    }

    final List<PieChartData> data = [];
    if (protein > 0) data.add(PieChartData(label: 'Protein', value: protein));
    if (carbs > 0) data.add(PieChartData(label: 'Carbs', value: carbs));
    if (fat > 0) data.add(PieChartData(label: 'Fats', value: fat));
    if (fiber > 0) data.add(PieChartData(label: 'Fiber', value: fiber));

    return Container(
      margin: const EdgeInsets.only(top: 16), // Add margin since it will be in a column
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macronutrients',
            style: TextStyle(
              color: AppColors.pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          PieChartWidget(data: data),
        ],
      ),
    );
  }
}
