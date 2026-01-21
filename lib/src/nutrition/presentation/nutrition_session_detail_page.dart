import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/nutrition_history_model.dart';
import '../api/nutrition_service.dart';

class NutritionSessionDetailPage extends StatefulWidget {
  final NutritionHistoryResponse sessionData;

  const NutritionSessionDetailPage({super.key, required this.sessionData});

  @override
  State<NutritionSessionDetailPage> createState() =>
      _NutritionSessionDetailPageState();
}

class _NutritionSessionDetailPageState
    extends State<NutritionSessionDetailPage> {
  bool _isDeleting = false;

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.black100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Meal',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this meal log? This action cannot be undone.',
          style: TextStyle(color: AppColors.white60),
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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSession();
    }
  }

  Future<void> _deleteSession() async {
    setState(() => _isDeleting = true);

    try {
      await NutritionApiService().deleteSession(widget.sessionData.session.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal deleted successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(
          '${widget.sessionData.session.mealType} Details',
          style: const TextStyle(color: AppColors.pureWhite),
        ),
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.pureWhite,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Delete button
          _isDeleting
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: _showDeleteConfirmation,
                  tooltip: 'Delete meal',
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images Carousel or Grid
            if (widget.sessionData.session.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.sessionData.session.images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        image: DecorationImage(
                          image: NetworkImage(
                            widget.sessionData.session.images[index],
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sessionData.session.caption ?? 'No caption',
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Logged Items',
                    style: TextStyle(
                      color: AppColors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.sessionData.logs
                      .map((log) => _buildFoodLogCard(log))
                      .toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodLogCard(NutritionHistoryLog log) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.foodName ?? 'Unknown Food',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty: ${log.quantity}',
                      style: const TextStyle(
                        color: AppColors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${log.calories} Cal',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.white10, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroItem(
                'Protein',
                '${log.protein}g',
                Icons.fitness_center,
              ),
              _buildMacroItem('Carbs', '${log.carbs}g', Icons.grain),
              _buildMacroItem('Fat', '${log.fat}g', Icons.opacity),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white60, size: 14),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.pureWhite,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.white60, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
