import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/services/upload_manager.dart';
import '../core/theme/app_colors.dart';

/// Helper to create color with alpha
Color _withAlpha(Color color, double opacity) {
  return color.withAlpha((opacity * 255).round());
}

/// A premium floating upload progress bar widget with themed animations
/// for diet and workout uploads
class UploadProgressBar extends StatefulWidget {
  const UploadProgressBar({super.key});

  @override
  State<UploadProgressBar> createState() => _UploadProgressBarState();
}

class _UploadProgressBarState extends State<UploadProgressBar>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _iconBounceController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Slide animation controller
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<double>(begin: 120, end: 0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    // Pulse animation for uploading state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Icon bounce animation
    _iconBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(parent: _iconBounceController, curve: Curves.easeInOut),
    );

    UploadManager().addListener(_onUploadManagerChange);
  }

  @override
  void dispose() {
    UploadManager().removeListener(_onUploadManagerChange);
    _slideController.dispose();
    _pulseController.dispose();
    _iconBounceController.dispose();
    super.dispose();
  }

  void _onUploadManagerChange() {
    if (UploadManager().tasks.isNotEmpty) {
      _slideController.forward();
    } else {
      _slideController.reverse();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = UploadManager().tasks;

    if (tasks.isEmpty && !_slideController.isAnimating) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(opacity: _fadeAnimation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _withAlpha(const Color(0xFF1A1A2E), 0.95),
              _withAlpha(const Color(0xFF16213E), 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _withAlpha(AppColors.primary, 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _withAlpha(AppColors.primary, 0.15),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: _withAlpha(Colors.black, 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tasks.map((task) => _buildTaskItem(task)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(UploadTask task) {
    final isSuccess = task.status == UploadStatus.success;
    final isFailed = task.status == UploadStatus.failed;
    final isUploading = task.status == UploadStatus.uploading;
    final isDiet = task.type.toLowerCase() == 'diet';

    // Theme colors based on type
    final primaryColor = isDiet 
        ? const Color(0xFF4CAF50) // Fresh green for diet
        : const Color(0xFFFF6B35); // Energetic orange for workout

    final gradientColors = isDiet
        ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]
        : [const Color(0xFFFF6B35), const Color(0xFFFF8E53)];

    String statusText = 'Uploading...';
    String statusEmoji = isDiet ? '🥗' : '💪';

    if (isSuccess) {
      statusText = 'Posted successfully!';
      statusEmoji = '✨';
    } else if (isFailed) {
      statusText = task.errorMessage ?? 'Upload failed';
      statusEmoji = '❌';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated themed icon container
              AnimatedBuilder(
                animation: isUploading ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  return Transform.scale(
                    scale: isUploading ? _pulseAnimation.value : 1.0,
                    child: child,
                  );
                },
                child: AnimatedBuilder(
                  animation: isUploading ? _bounceAnimation : const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, isUploading ? _bounceAnimation.value : 0),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isSuccess 
                          ? const LinearGradient(
                              colors: [Color(0xFF00E676), Color(0xFF69F0AE)],
                            )
                          : isFailed
                              ? const LinearGradient(
                                  colors: [Color(0xFFFF5252), Color(0xFFFF8A80)],
                                )
                              : LinearGradient(colors: gradientColors),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _withAlpha(
                            isSuccess ? const Color(0xFF00E676) : 
                                    isFailed ? const Color(0xFFFF5252) : primaryColor,
                            0.4,
                          ),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: isUploading
                          ? _buildAnimatedIcon(isDiet)
                          : Text(
                              statusEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Text content with enhanced styling
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUploading)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _withAlpha(primaryColor, 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _withAlpha(primaryColor, 0.3),
                              ),
                            ),
                            child: Text(
                              '${(task.progress * 100).toInt()}%',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isUploading) ...[
                          _buildPulsingDot(primaryColor),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          statusText,
                          style: TextStyle(
                            color: isSuccess
                                ? const Color(0xFF00E676)
                                : isFailed
                                    ? const Color(0xFFFF5252)
                                    : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Close button for failed uploads
              if (isFailed)
                GestureDetector(
                  onTap: () => UploadManager().removeTask(task.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _withAlpha(Colors.white, 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              
              // Success checkmark animation
              if (isSuccess)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _withAlpha(const Color(0xFF00E676), 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF00E676),
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),

          // Enhanced progress bar
          if (isUploading || isSuccess) ...[
            const SizedBox(height: 14),
            _buildEnhancedProgressBar(task, gradientColors, isSuccess),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(bool isDiet) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Spinning background circle for uploading
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _pulseController.value * 2 * math.pi,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _withAlpha(Colors.white, 0.3),
                    width: 2,
                  ),
                ),
              ),
            );
          },
        ),
        // Icon
        Text(
          isDiet ? '🥗' : '💪',
          style: const TextStyle(fontSize: 22),
        ),
      ],
    );
  }

  Widget _buildPulsingDot(Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _withAlpha(color, _pulseAnimation.value),
            boxShadow: [
              BoxShadow(
                color: _withAlpha(color, 0.5 * _pulseAnimation.value),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedProgressBar(UploadTask task, List<Color> gradientColors, bool isSuccess) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          // Background
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: _withAlpha(Colors.white, 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          // Animated progress
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: isSuccess ? 1.0 : task.progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSuccess 
                          ? [const Color(0xFF00E676), const Color(0xFF69F0AE)]
                          : gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: _withAlpha(
                          isSuccess ? const Color(0xFF00E676) : gradientColors.first,
                          0.5,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Shimmer effect while uploading
          if (!isSuccess && task.progress < 1.0)
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: task.progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              _withAlpha(Colors.white, 0.3 * _pulseAnimation.value),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// A wrapper widget that positions the upload progress bar above the navigation bar
class UploadProgressOverlay extends StatelessWidget {
  final Widget child;
  final double bottomPadding;

  const UploadProgressOverlay({
    super.key,
    required this.child,
    this.bottomPadding = 100, // Account for nav bar height
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomPadding,
          child: const UploadProgressBar(),
        ),
      ],
    );
  }
}
