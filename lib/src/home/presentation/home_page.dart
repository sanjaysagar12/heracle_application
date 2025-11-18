import 'package:flutter/material.dart';
import 'package:heracle/core/theme/app_colors.dart';
import 'package:heracle/core/theme/app_theme.dart';
import 'package:heracle/src/camera/presentation/camera_tab.dart';
import 'package:heracle/src/feed/presentation/feed_tab.dart';
import '../../../widgets/nav_bar.dart';
import 'home_tab.dart';
import '../../profile/presentation/profile_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  final pages = [
    HomeTab(),
    CameraTab(),
    FeedTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: IndexedStack(index: _index, children: pages),

      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
        },
      ),
    );
  }
}
