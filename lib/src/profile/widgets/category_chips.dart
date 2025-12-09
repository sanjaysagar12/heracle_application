import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';

class CategoryChips extends StatelessWidget {
  final List<WorkoutCategory> categories;
  final Function(String) onCategorySelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildChip(category),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildChip(WorkoutCategory category) {
    final isSelected = category.isSelected;
    return GestureDetector(
      onTap: () => onCategorySelected(category.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.greyDark,
            width: 1.5,
          ),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            color: isSelected ? AppColors.black : AppColors.pureWhite,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
