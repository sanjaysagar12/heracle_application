import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'line_chart_widget.dart';
import 'pie_chart_widget.dart';

class BarData {
  final String label;
  final double value;
  const BarData({required this.label, required this.value});
}

enum ChartType { bar, line, pie, area }

class ChartData {
  final String title;
  final List<BarData> data;
  final ChartType type;
  const ChartData({
    required this.title,
    required this.data,
    this.type = ChartType.bar,
  });
}

class BarChartCard extends StatelessWidget {
  final List<ChartData> charts;
  final double height;

  const BarChartCard({
    super.key,
    required this.charts,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (charts.isEmpty) return const SizedBox.shrink();

    if (charts.length == 1) {
      return _buildSingleChart(charts[0]);
    }

    return _buildCarousel();
  }

  Widget _buildSingleChart(ChartData chartData) {
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
          Text(
            chartData.title,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: height,
            child: CustomPaint(
              size: Size.infinite,
              painter: chartData.type == ChartType.bar
                  ? _BarChartPainter(data: chartData.data)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          // x-axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: chartData.data.map((d) {
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

  Widget _buildCarousel() {
    return _BarChartCarousel(charts: charts, height: height);
  }
}

class _BarChartCarousel extends StatefulWidget {
  final List<ChartData> charts;
  final double height;

  const _BarChartCarousel({required this.charts, required this.height});

  @override
  State<_BarChartCarousel> createState() => _BarChartCarouselState();
}

class _BarChartCarouselState extends State<_BarChartCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
          SizedBox(
            height: widget.height + 70, // title + chart + labels
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: widget.charts.length,
              itemBuilder: (context, index) {
                final chartData = widget.charts[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chartData.title,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: widget.height,
                      child: _buildChartPainter(chartData),
                    ),
                    const SizedBox(height: 8),
                    if (chartData.type != ChartType.pie)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: chartData.data.map((d) {
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
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.charts.length,
              (index) => Container(
                width: _currentPage == index ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.pureWhite : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPainter(ChartData chartData) {
    switch (chartData.type) {
      case ChartType.bar:
        return CustomPaint(
          size: Size.infinite,
          painter: _BarChartPainter(data: chartData.data),
        );
      case ChartType.line:
        return LineChartWidget(
          data: chartData.data.map((d) => LineChartData(label: d.label, value: d.value)).toList(),
          height: widget.height,
        );
      case ChartType.pie:
        return PieChartWidget(
          data: chartData.data.map((d) => PieChartData(label: d.label, value: d.value)).toList(),
          height: widget.height,
        );
      case ChartType.area:
        return CustomPaint(
          size: Size.infinite,
          painter: _AreaChartPainter(data: chartData.data),
        );
    }
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

class _AreaChartPainter extends CustomPainter {
  final List<BarData> data;

  _AreaChartPainter({required this.data});

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

    // create path for area
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

    // close path for area fill
    path.lineTo(points.last.dx, size.height);
    path.lineTo(points.first.dx, size.height);
    path.close();

    // draw area with linear gradient
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.5),
          AppColors.primary.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, areaPaint);

    // draw border line
    final linePath = Path();
    for (int i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }

    // draw line with glow
    final glowPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawPath(linePath, glowPaint);

    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    // draw points
    for (final point in points) {
      final pointPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4, pointPaint);

      final centerPaint = Paint()
        ..color = AppColors.pureWhite
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 2, centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
