import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../storage/steps_storage.dart';

class StepsHistoryPage extends StatefulWidget {
  const StepsHistoryPage({super.key});

  @override
  State<StepsHistoryPage> createState() => _StepsHistoryPageState();
}

class _StepsHistoryPageState extends State<StepsHistoryPage> {
  final StepsStorage _storage = StepsStorage();
  Map<String, int> _history = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _storage.getStepsHistory();
      // Sort history by date descending
      final sortedKeys = history.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      
      final Map<String, int> sortedHistory = {
        for (var key in sortedKeys) key: history[key]!
      };

      setState(() {
        _history = sortedHistory;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = DateTime(now.year, now.month, now.day).difference(DateTime(date.year, date.month, date.day)).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else {
        return DateFormat('EEE, MMM dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: const Text('Steps History', style: TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _history.isEmpty
              ? const Center(child: Text('No history available', style: TextStyle(color: AppColors.white60)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final dateKey = _history.keys.elementAt(index);
                    final steps = _history[dateKey]!;
                    final calsBurned = (steps * 0.04).round();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.black100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(dateKey),
                                  style: const TextStyle(
                                    color: AppColors.pureWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.local_fire_department, size: 14, color: AppColors.white60),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$calsBurned kcal',
                                      style: const TextStyle(
                                        color: AppColors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$steps',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'steps',
                                style: TextStyle(
                                  color: AppColors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
