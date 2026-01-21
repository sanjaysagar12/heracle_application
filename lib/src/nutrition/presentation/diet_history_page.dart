import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../api/nutrition_service.dart';
import '../data/nutrition_history_model.dart';
import 'nutrition_session_detail_page.dart';

class DietHistoryPage extends StatefulWidget {
  const DietHistoryPage({super.key});

  @override
  State<DietHistoryPage> createState() => _DietHistoryPageState();
}

class _DietHistoryPageState extends State<DietHistoryPage> {
  final NutritionApiService _service = NutritionApiService();
  List<NutritionHistoryResponse> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final data = await _service.getNutritionHistory();
      setState(() {
        _sessions = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Group items by date string (Today, Yesterday, Mon Jan 05)
  Map<String, List<NutritionHistoryResponse>> _groupedItems() {
    final grouped = <String, List<NutritionHistoryResponse>>{};

    for (var item in _sessions) {
      final date = item.session.date.toLocal(); // Ensure local time
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final dateOnly = DateTime(date.year, date.month, date.day);

      String header;
      if (dateOnly == today) {
        header = 'Today';
      } else if (dateOnly == yesterday) {
        header = 'Yesterday';
      } else {
        header = DateFormat('EEE, MMM dd').format(date);
      }

      if (!grouped.containsKey(header)) {
        grouped[header] = [];
      }
      grouped[header]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedItems();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text(
          'Diet History',
          style: TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
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
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : grouped.isEmpty
          ? const Center(
              child: Text(
                'No history available',
                style: TextStyle(color: AppColors.white60),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final header = grouped.keys.elementAt(index);
                final items = grouped[header]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        header,
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...items.map((item) => _buildSessionCard(item)).toList(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSessionCard(NutritionHistoryResponse item) {
    // Calculate total calories from logs
    final cals = item.logs.fold(0, (sum, log) => sum + log.calories);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NutritionSessionDetailPage(sessionData: item),
          ),
        );

        // If an item was deleted, refresh the list
        if (result == true) {
          _loadHistory();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: item.session.images.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(item.session.images.first),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: item.session.images.isEmpty ? AppColors.greyDark : null,
              ),
              child: item.session.images.isEmpty
                  ? const Icon(
                      Icons.image_not_supported,
                      color: AppColors.white60,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.session.mealType,
                    style: const TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.session.caption != null &&
                      item.session.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        item.session.caption!,
                        style: const TextStyle(
                          color: AppColors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  // Hardcoded/Placeholder logic since API response struct provided lacks calories
                  '${cals > 0 ? cals : '---'}Cal',
                  style: const TextStyle(
                    color: Color(0xFFD0FD3E), // Neon yellow/green from image
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
