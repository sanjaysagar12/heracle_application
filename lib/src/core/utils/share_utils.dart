import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';

class ShareUtils {
  static const String appDomain = 'https://heracle.fit'; // Update with actual domain

  static Future<void> sharePost({
    required String title,
    required String content,
    String? postId,
    String? type,
  }) async {
    final String shareText = _buildShareText(title, content, postId, type);
    await Share.share(shareText);
  }

  static String _buildShareText(String title, String content, String? postId, String? type) {
    String text = '$title\n\n$content';
    if (postId != null && type != null) {
      text += '\n\nCheck it out on Heracle: $appDomain/$type/$postId';
      text += '\nDirect App Link: heracle://$type/$postId';
    } else {
      text += '\n\nSent via Heracle App';
    }
    return text;
  }

  static Future<void> copyLink({
    required BuildContext context,
    required String postId,
    required String type,
  }) async {
    final String link = '$appDomain/$type/$postId';
    await Clipboard.setData(ClipboardData(text: link));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link copied to clipboard!'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> showShareOptions({
    required BuildContext context,
    required String title,
    required String content,
    required String postId,
    required String type,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.black100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppColors.pureWhite),
              title: const Text('Share via...', style: TextStyle(color: AppColors.pureWhite)),
              onTap: () {
                Navigator.pop(context);
                sharePost(title: title, content: content, postId: postId, type: type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.pureWhite),
              title: const Text('Copy Link', style: TextStyle(color: AppColors.pureWhite)),
              onTap: () {
                Navigator.pop(context);
                copyLink(context: context, postId: postId, type: type);
              },
            ),
          ],
        ),
      ),
    );
  }
}
