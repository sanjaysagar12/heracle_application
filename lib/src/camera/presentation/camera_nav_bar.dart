import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:heracle/core/theme/app_colors.dart';

class CameraNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CameraNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(bottom: 20, top: 10, left: 20, right: 20),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem('assets/icons/home.svg', 0),
            _navItem('assets/icons/camera.svg', 1),
            _navItem('assets/icons/feed.svg', 2),
            _navItem('assets/icons/profile.svg', 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(String asset, int index) {
    final bool selected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: SvgPicture.asset(
          asset,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            selected ? Colors.black : Colors.white,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
