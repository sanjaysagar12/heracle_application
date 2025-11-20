import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class FeedSkeletonLoading extends StatefulWidget {
  const FeedSkeletonLoading({super.key});

  @override
  State<FeedSkeletonLoading> createState() => _FeedSkeletonLoadingState();
}

class _FeedSkeletonLoadingState extends State<FeedSkeletonLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomScrollView(
          slivers: [
            // Stories skeleton
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 110,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              _buildShimmer(70, 70, isCircle: true),
                              const SizedBox(height: 6),
                              _buildShimmer(60, 12),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildShimmer(150, 24),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Grid skeleton
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildShimmer(double.infinity, double.infinity,
                        borderRadius: 16);
                  },
                  childCount: 6,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmer(double width, double height,
      {bool isCircle = false, double borderRadius = 8}) {
    final shimmerGradient = LinearGradient(
      colors: [
        AppColors.greyDark,
        AppColors.black100,
        AppColors.greyDark,
      ],
      stops: [
        0.0,
        _animationController.value,
        1.0,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: shimmerGradient,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}
