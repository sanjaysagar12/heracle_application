import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/src/story/presentation/create_story_page.dart';

class ShareBottomSheet extends StatefulWidget {
  final String filePath;
  final String? caption;
  final VoidCallback? onDownload; // Added

  const ShareBottomSheet({
    super.key,
    required this.filePath,
    this.caption,
    this.onDownload, // Added
  });

  @override
  State<ShareBottomSheet> createState() => _ShareBottomSheetState();
}

class _ShareBottomSheetState extends State<ShareBottomSheet> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _options = [
    {
      'title': 'Share as Story (Public)',
      'subtitle': 'Public Story',
      'icon': Icons.person,
    },
    {
      'title': 'Share as Story (Mutuals)',
      'subtitle': '12+ People',
      'icon': Icons.people,
    },
    {
      'title': 'Share as Spotlight',
      'subtitle': 'Public Post',
      'icon': Icons.star,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(_options.length, (index) {
            final option = _options[index];
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.transparent, // Hit test
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[800],
                      child: Icon(option['icon'], color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['title'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option['subtitle'],
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFFD0FD3E) : Colors.transparent,
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey[700]!, width: 2),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.black)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to CreateStoryPage
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateStoryPage(
                            filePath: widget.filePath,
                            caption: widget.caption,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send, color: Colors.black),
                    label: const Text(
                      "Share",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD0FD3E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD0FD3E), width: 2),
                ),
                child: IconButton(
                  onPressed: () {
                    widget.onDownload?.call(); // Trigger download callback
                  },
                  icon: const Icon(Icons.download, color: Color(0xFFD0FD3E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
