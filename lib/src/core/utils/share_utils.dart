import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/share_card.dart';

class ShareUtils {
  static const String appDomain = 'https://heracle.fit';
  static final ScreenshotController screenshotController = ScreenshotController();

  static Future<void> sharePost({
    required String title,
    required String content,
    required String username,
    String? profileImageUrl,
    String? postId,
    String? type,
    String? imageUrl,
  }) async {
    // Automatically copy link to clipboard for Instagram stickers
    if (postId != null && type != null) {
      final String link = '$appDomain/$type/$postId';
      await Clipboard.setData(ClipboardData(text: link));
    }

    try {
      // Generate the beautiful share card with proper context
      final Uint8List? imageBytes = await screenshotController.captureFromWidget(
        Container(
          width: 375, // Standard mobile width for layout
          height: 667, // Standard mobile height
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 667),
              devicePixelRatio: 3.0,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Material(
                child: ShareCard(
                  title: title,
                  content: content,
                  username: username,
                  profileImageUrl: profileImageUrl,
                  imageUrl: imageUrl,
                ),
              ),
            ),
          ),
        ),
        pixelRatio: 3.0, // High quality
        delay: const Duration(milliseconds: 200),
      );

      if (imageBytes != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/heracle_share_card.png').create();
        await file.writeAsBytes(imageBytes);

        String shareText = _buildShareText(title, content, postId, type);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
          subject: title,
        );
        return;
      }
    } catch (e) {
      debugPrint('Error generating share card: $e');
      // Fallback to simple text share
    }

    await Share.share(_buildShareText(title, content, postId, type), subject: title);
  }

  static String _buildShareText(String title, String content, String? postId, String? type) {
    String text = '$title';
    if (postId != null && type != null) {
      text += '\n\nCheck it out here: $appDomain/$type/$postId';
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
    required String username,
    String? profileImageUrl,
    required String postId,
    required String type,
    String? imageUrl,
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
              title: const Text('Share with others', style: TextStyle(color: AppColors.pureWhite)),
              onTap: () {
                Navigator.pop(context);
                sharePost(
                  title: title,
                  content: content,
                  username: username,
                  profileImageUrl: profileImageUrl,
                  postId: postId,
                  type: type,
                  imageUrl: imageUrl,
                );
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
            const SizedBox(height: 10),
            const Divider(color: AppColors.white10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Link is copied automatically! Use the "Link Sticker" on Instagram to make it clickable.',
                      style: TextStyle(
                        color: AppColors.white70,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
