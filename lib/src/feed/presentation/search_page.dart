import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../route.dart';
import '../data/stories_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final StoriesRepository _storiesRepository = StoriesRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  List<SearchUser> _searchResults = [];
  List<SearchUser> _recentSearches = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    // Auto focus the search bar when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final recents = await _storiesRepository.getRecentSearches();
    setState(() {
      _recentSearches = recents;
    });
  }

  Future<void> _addToRecents(SearchUser user) async {
    await _storiesRepository.addToRecentSearches(user);
    _loadRecentSearches();
  }

  Future<void> _removeFromRecents(String userId) async {
    await _storiesRepository.removeFromRecentSearches(userId);
    _loadRecentSearches();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        return;
      }
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _storiesRepository.searchUsers(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Search failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showingRecents = _searchController.text.isEmpty;
    final List<SearchUser> data = showingRecents ? _recentSearches : _searchResults;

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search users, posts, hashtags...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        suffixIcon: const Icon(Icons.search, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Results List
            Expanded(
              child: _buildList(data, showingRecents),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<SearchUser> data, bool showingRecents) {
    if (data.isEmpty && !showingRecents && _isSearching) {
      return const Center(
        child: Text(
          'No users found',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      itemCount: showingRecents ? data.length + 1 : data.length,
      itemBuilder: (context, index) {
        if (showingRecents && index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text(
                  'Recent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Implement See all
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }

        final int itemIndex = showingRecents ? index - 1 : index;
        if (itemIndex < 0 || itemIndex >= data.length) return const SizedBox.shrink();
        
        final user = data[itemIndex];
        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty 
                ? NetworkImage(user.avatarUrl!) 
                : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty 
                ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white)) 
                : null,
          ),
          title: Text(
            user.username,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${user.name} • ${user.isFollowing ? 'Following' : 'Suggested'}',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: showingRecents
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  onPressed: () => _removeFromRecents(user.id),
                )
              : null,
          onTap: () {
            _addToRecents(user);
            Navigator.pushNamed(
              context, 
              AppRoutes.profile,
              arguments: user.username,
            );
          },
        );
      },
    );
  }
}
