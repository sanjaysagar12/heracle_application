class Session {
  final String id;
  final String title;
  final String content;
  final String category;
  final List<String> avatars;
  final int exercisesCount;

  Session({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.avatars,
    required this.exercisesCount,
  });
}

class SessionRepository {
  SessionRepository();

  Future<List<Session>> getSessions() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      Session(
        id: 's1',
        title: 'Circuit day',
        content: 'Full body circuit focusing on strength and conditioning.',
        category: 'Functional',
        avatars: [
          'https://i.pravatar.cc/150?img=1',
          'https://i.pravatar.cc/150?img=2',
          'https://i.pravatar.cc/150?img=3',
        ],
        exercisesCount: 4,
      ),
      Session(
        id: 's2',
        title: 'Chest day 1',
        content: 'Heavy presses and perfect form. Focus on tempo and full range.',
        category: 'Biceps',
        avatars: [
          'https://i.pravatar.cc/150?img=4',
          'https://i.pravatar.cc/150?img=5',
          'https://i.pravatar.cc/150?img=6',
        ],
        exercisesCount: 5,
      ),
      // add more mock sessions as needed
    ];
  }
}
