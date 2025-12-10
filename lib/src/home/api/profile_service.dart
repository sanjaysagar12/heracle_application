class ProfileService {
  Future<Map<String, dynamic>> getProfile() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data
    return {
      'name': 'Eren Yeager',
      'age': 20,
      'profileImageUrl': 'https://tse3.mm.bing.net/th/id/OIP.dvSVSBNTSG_uMW_J4J5pWwHaHa?w=1000&h=1000&rs=1&pid=ImgDetMain&o=7&rm=3',
      'hasStory': true,
    };
  }
}
