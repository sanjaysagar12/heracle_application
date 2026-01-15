import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../core/theme/app_colors.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, left: 16, right: 16),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _navItem('assets/icons/home.svg', 0),
              const SizedBox(width: 24),
              _navItem('assets/icons/camera.svg', 1),
              const SizedBox(width: 24),
              _navItem('assets/icons/feed.svg', 2),
              const SizedBox(width: 24),
              _navItem('assets/icons/profile.svg', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String asset, int index) {
    final bool selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          asset,
          width: 22,
          height: 22,
          color: selected ? Colors.black : AppColors.white70,
        ),
      ),
    );
  }
}
