import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/user_suggestion.dart';
import 'user_suggestion_card.dart';

class UserSuggestionsCarousel extends StatefulWidget {
  final List<UserSuggestion> suggestions;
  final Function(String) onFollow;
  final VoidCallback onSeeAll;

  const UserSuggestionsCarousel({
    super.key,
    required this.suggestions,
    required this.onFollow,
    required this.onSeeAll,
  });

  @override
  State<UserSuggestionsCarousel> createState() =>
      _UserSuggestionsCarouselState();
}

class _UserSuggestionsCarouselState extends State<UserSuggestionsCarousel> {
  // Keep track of dismissed suggestions locally
  final Set<String> _dismissedIds = {};
  // Keep track of followed suggestions locally
  final Set<String> _followedIds = {};

  @override
  Widget build(BuildContext context) {
    final activeSuggestions = widget.suggestions
        .where((s) => !_dismissedIds.contains(s.id))
        .toList();

    if (activeSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Suggested for you',
                style: TextStyle(
                  color: AppColors.pureWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: widget.onSeeAll,
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: Color(0xFF4C6FFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240, // Height for the card
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: activeSuggestions.length,
            itemBuilder: (context, index) {
              final suggestion = activeSuggestions[index];
              return UserSuggestionCard(
                suggestion: suggestion,
                isFollowing: _followedIds.contains(suggestion.id),
                onFollow: () {
                  widget.onFollow(suggestion.username);
                  setState(() {
                    _followedIds.add(suggestion.id);
                  });
                },
                onDismiss: () {
                  setState(() {
                    _dismissedIds.add(suggestion.id);
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
