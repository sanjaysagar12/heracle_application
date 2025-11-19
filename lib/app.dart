import 'package:flutter/material.dart';

import 'src/camera/presentation/camera_page.dart';
import 'src/feed/presentation/feed_page.dart';
import 'src/home/presentation/home_page.dart';
import 'src/profile/presentation/profile_page.dart';
import 'widgets/nav_bar.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  int _index = 0;

  final pages = [
    const HomePage(),
    CameraPage(),
    FeedPage(),
    ProfilePage(),
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
