import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/user_suggestion.dart';
import 'user_suggestion_card.dart';

class UserSuggestionsCarousel extends StatefulWidget {
  final List<UserSuggestion> suggestions;
  final Set<String> followedIds;
  final Function(String, String) onFollow;
  final VoidCallback onSeeAll;

  const UserSuggestionsCarousel({
    super.key,
    required this.suggestions,
    required this.followedIds,
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
  // Keep track of locally interacted suggestions (to keep them visible as "Following")
  final Set<String> _localInteractedIds = {};

  @override
  Widget build(BuildContext context) {
    // Logic: Show suggestion if:
    // 1. Not dismissed locally AND
    // 2. (Not followed globally OR followed locally in this session)
    final activeSuggestions = widget.suggestions.where((s) {
      if (_dismissedIds.contains(s.id)) return false;

      final isFollowedGlobally = widget.followedIds.contains(s.id);
      final isInteractedLocally = _localInteractedIds.contains(s.id);

      if (isFollowedGlobally && !isInteractedLocally) return false;

      return true;
    }).toList();

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
                isFollowing: widget.followedIds.contains(suggestion.id),
                onFollow: () {
                  widget.onFollow(suggestion.username, suggestion.id);
                  setState(() {
                    _localInteractedIds.add(suggestion.id);
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
