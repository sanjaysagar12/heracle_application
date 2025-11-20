import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class LineChartWidget extends StatelessWidget {
  final List<LineChartData> data;
  final double height;

  const LineChartWidget({
    super.key,
    required this.data,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(data: data),
    );
  }
}

class LineChartData {
  final String label;
  final double value;
  const LineChartData({required this.label, required this.value});
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartData> data;
  _LineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paintGrid = Paint()
      ..color = AppColors.greyLight.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // draw horizontal grid lines
    final int gridLines = 4;
    for (int i = 0; i <= gridLines; i++) {
      final dy = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paintGrid);
    }

    // compute max value
    double maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) maxVal = 1;

    final leftPadding = 16.0;
    final rightPadding = 16.0;
    final usableWidth = size.width - leftPadding - rightPadding;
    final spacing = usableWidth / (data.length - 1);

    double mapY(double val) {
      final normalized = val / maxVal;
      return size.height - (normalized * size.height);
    }

    // create path for line
    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = leftPadding + (spacing * i);
      final y = mapY(data[i].value);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // draw gradient fill under line
    final fillPath = Path.from(path);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.lineTo(points.first.dx, size.height);
    fillPath.close();

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.3),
          AppColors.primary.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, gradientPaint);

    // draw line with glow effect
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // draw points with rings
    for (final point in points) {
      // outer ring
      final outerRingPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(point, 8, outerRingPaint);

      // inner circle
      final pointPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 5, pointPaint);

      // white center
      final centerPaint = Paint()
        ..color = AppColors.pureWhite
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 2, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
