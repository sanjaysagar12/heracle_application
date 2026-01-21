import 'package:flutter/material.dart';
import '../core/services/upload_manager.dart';
import '../core/theme/app_colors.dart';

/// A simple, human-written upload progress bar that follows the app's brand theme.
/// Uses the primary brand color (Yellow/Lime) and standard Flutter components.
class UploadProgressBar extends StatefulWidget {
  const UploadProgressBar({super.key});

  @override
  State<UploadProgressBar> createState() => _UploadProgressBarState();
}

class _UploadProgressBarState extends State<UploadProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _fadeInController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeInController, curve: Curves.easeIn);
    
    UploadManager().addListener(_onUploadManagerChange);
  }

  @override
  void dispose() {
    UploadManager().removeListener(_onUploadManagerChange);
    _fadeInController.dispose();
    super.dispose();
  }

  void _onUploadManagerChange() {
    if (UploadManager().tasks.isNotEmpty) {
      _fadeInController.forward();
    } else {
      _fadeInController.reverse();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tasks = UploadManager().tasks;
    if (tasks.isEmpty && !_fadeInController.isAnimating) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E), // Dark grey consistent with app theme
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: const Color(0x4D000000), // Black with 30% opacity
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: tasks.map((task) => _buildTaskRow(task)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskRow(UploadTask task) {
    final isSuccess = task.status == UploadStatus.success;
    final isFailed = task.status == UploadStatus.failed;
    final isUploading = task.status == UploadStatus.uploading;
    
    // Using the brand primary color (Yellow/Lime) as requested
    const themeYellow = AppColors.primary; 

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          Row(
            children: [
              // Standard loading circle or status icon
              SizedBox(
                width: 24,
                height: 24,
                child: isUploading
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(themeYellow),
                      )
                    : Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? themeYellow : Colors.redAccent,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Text(
                      isSuccess 
                          ? 'Posted successfully' 
                          : isFailed 
                              ? (task.errorMessage ?? 'Failed to upload') 
                              : 'Uploading...',
                      style: TextStyle(
                        color: isFailed ? Colors.redAccent : Colors.white70,
                        fontSize: 12,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress percentage
              if (isUploading)
                Text(
                  '${(task.progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: themeYellow,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                
              if (isFailed)
                IconButton(
                  onPressed: () => UploadManager().removeTask(task.id),
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          
          // Simple Linear Progress Bar
          if (isUploading || isSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: isSuccess ? 1.0 : task.progress,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(themeYellow),
                  minHeight: 4,
                ),
              ),
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
