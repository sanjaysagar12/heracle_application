import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BarData {
  final String label;
  final double value;
  const BarData({required this.label, required this.value});
}

class BarChartCard extends StatelessWidget {
  final String title;
  final List<BarData> data;
  final double height;

  const BarChartCard({
    super.key,
    required this.title,
    required this.data,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                style: const TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
              Row(
                children: [
                  _dot(true),
                  const SizedBox(width: 6),
                  _dot(false),
                  const SizedBox(width: 6),
                  _dot(false),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: _BarChartPainter(data: data),
            ),
          ),
          const SizedBox(height: 8),
          // x-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: data.map((d) {
              return Expanded(
                child: Text(
                  d.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.white60, fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool active) {
    return Container(
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.pureWhite : AppColors.greyLight,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<BarData> data;
  _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintGrid = Paint()
      ..color = AppColors.greyLight.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // draw horizontal grid lines (4)
    final int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    // compute max value
    double maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) maxVal = 1;
    final leftPadding = 8.0;
    final rightPadding = 8.0;
    final usableWidth = size.width - leftPadding - rightPadding;
    final barSpacing = usableWidth / data.length;
    final barWidth = barSpacing * 0.5;

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final xCenter = leftPadding + barSpacing * i + barSpacing / 2;

      double mapY(double val) {
        final normalized = val / maxVal;
        return size.height - (normalized * size.height);
      }

      final barTop = mapY(d.value);
      final barBottom = size.height;

      final Rect barRect = Rect.fromLTRB(
        xCenter - barWidth / 2,
        barTop,
        xCenter + barWidth / 2,
        barBottom,
      );

      // gradient paint for bar
      final Paint barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.95),
            AppColors.primary.withOpacity(0.7),
          ],
        ).createShader(barRect);

      // draw shadow / glow (subtle)
      final shadowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      final shadowRect = barRect.inflate(2);
      canvas.drawRRect(RRect.fromRectAndRadius(shadowRect, const Radius.circular(6)), shadowPaint);

      // draw bar with rounded corners
      final rrect = RRect.fromRectAndRadius(barRect, const Radius.circular(6));
      canvas.drawRRect(rrect, barPaint);

      // top highlight
      final highlightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.12),
            Colors.transparent,
          ],
        ).createShader(barRect)
        ..blendMode = BlendMode.overlay;
      canvas.drawRRect(rrect, highlightPaint);

      // subtle border
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.white40.withOpacity(0.06)
        ..strokeWidth = 0.8;
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
