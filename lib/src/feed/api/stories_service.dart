class StoriesService {
  Future<List<Map<String, dynamic>>> getStories() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': '1',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'hasStory': true,
        'isViewed': false,
        'stories': [
          {
            'id': '1_1',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
            'text': 'Leg day completed! 💪',
            'duration': 5,
          },
          {
            'id': '1_2',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=800',
            'text': 'New PR on squats! 🏋️',
            'duration': 5,
          },
          {
            'id': '1_3',
            'type': 'text',
            'text': 'Gym motivation:\n\n"The pain you feel today will be the strength you feel tomorrow"',
            'backgroundColor': '#D4FC79',
            'duration': 4,
          },
        ],
      },
      {
        'id': '2',
        'username': 'Johnny Bhai',
        'profileImage': 'https://i.pravatar.cc/150?img=12',
        'hasStory': true,
        'isViewed': false,
        'stories': [
          {
            'id': '2_1',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
            'text': 'Cardio session 🏃‍♂️',
            'duration': 5,
          },
          {
            'id': '2_2',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=800',
            'text': 'Morning grind 🌅',
            'duration': 5,
          },
        ],
      },
      {
        'id': '3',
        'username': 'Joseph Ismati',
        'profileImage': 'https://i.pravatar.cc/150?img=33',
        'hasStory': true,
        'isViewed': false,
        'stories': [
          {
            'id': '3_1',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=800',
            'text': 'Chest and back today',
            'duration': 5,
          },
          {
            'id': '3_2',
            'type': 'text',
            'text': 'Protein shake recipe:\n\n- 2 scoops protein\n- 1 banana\n- Almond milk\n- Peanut butter',
            'backgroundColor': '#FF6B6B',
            'duration': 6,
          },
          {
            'id': '3_3',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=800',
            'text': 'Post workout meal 🍗',
            'duration': 5,
          },
        ],
      },
      {
        'id': '4',
        'username': 'Ronnie Herr',
        'profileImage': 'https://i.pravatar.cc/150?img=56',
        'hasStory': true,
        'isViewed': false,
        'stories': [
          {
            'id': '4_1',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800',
            'text': 'Arm day 💪',
            'duration': 5,
          },
        ],
      },
      {
        'id': '5',
        'username': 'Sarah Miller',
        'profileImage': 'https://i.pravatar.cc/150?img=47',
        'hasStory': true,
        'isViewed': false,
        'stories': [
          {
            'id': '5_1',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
            'text': 'Yoga flow 🧘‍♀️',
            'duration': 5,
          },
          {
            'id': '5_2',
            'type': 'image',
            'imageUrl': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800',
            'text': 'Stretching is important!',
            'duration': 5,
          },
        ],
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getDiscoverStories() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      {
        'id': '1',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'had a nice workout sessions',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400',
        'platform': 'TikTok',
        'platformHandle': '@radhew',
        'label': 'AB ATTACK',
        'timeAgo': '2h ago',
        'isLiked': false,
        'likesCount': 124,
        'likedBy': [
          {'name': 'Sarah Miller', 'profileImage': 'https://i.pravatar.cc/150?img=47', 'isFollowing': false},
          {'name': 'Johnny Bhai', 'profileImage': 'https://i.pravatar.cc/150?img=12', 'isFollowing': true},
          {'name': 'Joseph Ismati', 'profileImage': 'https://i.pravatar.cc/150?img=33', 'isFollowing': false},
          {'name': 'Ronnie Herr', 'profileImage': 'https://i.pravatar.cc/150?img=56', 'isFollowing': true},
          {'name': 'Emma Wilson', 'profileImage': 'https://i.pravatar.cc/150?img=20', 'isFollowing': false},
        ],
      },
      {
        'id': '2',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'had a nice workout sessions',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1583454110551-21f2fa2afe61?w=400',
        'platform': 'Instagram',
        'platformHandle': '@fitness_queen',
        'timeAgo': '5h ago',
        'isLiked': false,
        'likesCount': 89,
        'likedBy': [
          {'name': 'Mike Johnson', 'profileImage': 'https://i.pravatar.cc/150?img=13', 'isFollowing': true},
          {'name': 'Lisa Anderson', 'profileImage': 'https://i.pravatar.cc/150?img=21', 'isFollowing': false},
          {'name': 'David Lee', 'profileImage': 'https://i.pravatar.cc/150?img=31', 'isFollowing': true},
        ],
      },
      {
        'id': '3',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'side effects of bodybuilding',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400',
        'platform': 'Instagram',
        'platformHandle': '@kendra_fit',
        'timeAgo': '8h ago',
        'isLiked': false,
        'likesCount': 256,
        'likedBy': [
          {'name': 'Alex Thompson', 'profileImage': 'https://i.pravatar.cc/150?img=15', 'isFollowing': false},
          {'name': 'Rachel Green', 'profileImage': 'https://i.pravatar.cc/150?img=25', 'isFollowing': true},
          {'name': 'Chris Brown', 'profileImage': 'https://i.pravatar.cc/150?img=35', 'isFollowing': false},
          {'name': 'Monica Geller', 'profileImage': 'https://i.pravatar.cc/150?img=40', 'isFollowing': true},
          {'name': 'Ross Smith', 'profileImage': 'https://i.pravatar.cc/150?img=50', 'isFollowing': false},
          {'name': 'Phoebe White', 'profileImage': 'https://i.pravatar.cc/150?img=55', 'isFollowing': false},
        ],
      },
      {
        'id': '4',
        'username': 'Kendra Jane',
        'profileImage': 'https://i.pravatar.cc/150?img=45',
        'content': 'had a nice workout sessions',
        'hashtags': ['Gymills'],
        'imageUrl': 'https://images.unsplash.com/photo-1571902943202-507ec2618e8f?w=400',
        'platform': 'YouTube',
        'platformHandle': '@kendraworkouts',
        'timeAgo': '1d ago',
        'isLiked': false,
        'likesCount': 432,
        'likedBy': [
          {'name': 'Tom Hanks', 'profileImage': 'https://i.pravatar.cc/150?img=11', 'isFollowing': true},
          {'name': 'Julia Roberts', 'profileImage': 'https://i.pravatar.cc/150?img=22', 'isFollowing': false},
          {'name': 'Brad Pitt', 'profileImage': 'https://i.pravatar.cc/150?img=32', 'isFollowing': true},
          {'name': 'Jennifer Aniston', 'profileImage': 'https://i.pravatar.cc/150?img=42', 'isFollowing': false},
        ],
      },
    ];
  }
}
