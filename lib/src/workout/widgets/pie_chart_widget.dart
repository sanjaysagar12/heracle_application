import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';

class PieChartWidget extends StatelessWidget {
  final List<PieChartData> data;
  final double height;

  const PieChartWidget({
    super.key,
    required this.data,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CustomPaint(
            size: Size.infinite,
            painter: _PieChartPainter(data: data),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = _getPieColor(index, item.label);
              final unit = _getUnit(item.label);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              color: AppColors.pureWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${item.value.toInt()}$unit',
                            style: const TextStyle(
                              color: AppColors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _getUnit(String label) {
    switch (label.toLowerCase()) {
      case 'calories':
        return ' kcal';
      case 'protein':
      case 'carbs':
      case 'fats':
        return 'g';
      default:
        return '';
    }
  }

  Color _getPieColor(int index, String label) {
    switch (label.toLowerCase()) {
      case 'calories':
        return const Color(0xFFFF6B6B);
      case 'protein':
        return const Color(0xFF4ECDC4);
      case 'carbs':
        return const Color(0xFFFFE66D);
      case 'fats':
        return const Color(0xFFFF9E5B);
      default:
        final colors = [
          AppColors.primary,
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFFF9800),
          const Color(0xFFE91E63),
          const Color(0xFF9C27B0),
        ];
        return colors[index % colors.length];
    }
  }
}

class PieChartData {
  final String label;
  final double value;
  const PieChartData({required this.label, required this.value});
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;

  _PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2.5;

    final total = data.fold(0.0, (sum, item) => sum + item.value);
    double startAngle = -math.pi / 2;

    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi;
      final color = _getPieColor(i, data[i].label);

      // Draw slice shadow
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 4),
        startAngle,
        sweepAngle,
        true,
        shadowPaint,
      );

      // Draw slice
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = AppColors.black100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = AppColors.black100
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  Color _getPieColor(int index, String label) {
    switch (label.toLowerCase()) {
      case 'calories':
        return const Color(0xFFFF6B6B);
      case 'protein':
        return const Color(0xFF4ECDC4);
      case 'carbs':
        return const Color(0xFFFFE66D);
      case 'fats':
        return const Color(0xFFFF9E5B);
      default:
        final colors = [
          AppColors.primary,
          const Color(0xFF4CAF50),
          const Color(0xFF2196F3),
          const Color(0xFFFF9800),
          const Color(0xFFE91E63),
          const Color(0xFF9C27B0),
        ];
        return colors[index % colors.length];
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
