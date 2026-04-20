import 'dart:async';
import 'package:flutter/material.dart';
import '../theme_provider.dart';
import '../components/primary_button.dart';
import '../services/map_service.dart';

/// Data model for a recent location entry.
class RecentLocation {
  final String name;
  final String subtitle;

  const RecentLocation({required this.name, required this.subtitle});
}

/// Add Location screen — search for a location via geocoding or pick from
/// recent ones.
class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  /// Geocoded results from the search
  List<GeocodedPlace> _searchResults = [];
  bool _isSearching = false;

  static const List<RecentLocation> _recentLocations = [
    RecentLocation(
      name: 'Little Adams Peak Ella',
      subtitle: 'Ella Road Wellawaya',
    ),
    RecentLocation(
      name: 'Little Adams Peak Ella',
      subtitle: 'Ella Road Wellawaya',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final results = await MapService.instance.geocodeAddress(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = isDarkMode(context);
    final bgColor = dark ? AppColors.darkBackground : Colors.white;
    final titleColor = dark ? Colors.white : Colors.black;
    final query = _searchController.text.trim();
    final showSearchResults = query.length >= 3;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Add Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: dark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(dark),
          ),

          const SizedBox(height: 24),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              showSearchResults ? 'Search Results' : 'Recent',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Results / Recent List ──
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : showSearchResults
                    ? _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                color:
                                    dark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return _buildSearchResultItem(place, dark);
                            },
                          )
                    : ListView.builder(
                        itemCount: _recentLocations.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          return _buildRecentItem(
                            _recentLocations[index],
                            dark,
                          );
                        },
                      ),
          ),

          // ── Confirm Location Button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                label: 'Confirm Location',
                onPressed: () {
                  Navigator.pop(context);
                },
                borderRadius: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search bar with map pin icon and optional mic button
  Widget _buildSearchBar(bool dark) {
    final fillColor = dark ? AppColors.darkSurface : Colors.grey[100]!;
    final hintColor = dark ? Colors.grey[500]! : Colors.grey[400]!;
    final textColor = dark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Map pin icon
          Icon(
            Icons.location_on,
            color: dark ? Colors.green : AppColors.primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 10),
          // Search text field
          Expanded(
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search here',
                hintStyle: TextStyle(color: hintColor),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          // Clear button when text present, mic when empty
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                });
              },
              child: Icon(Icons.close, color: Colors.grey[500], size: 20),
            )
          else if (dark)
            Icon(Icons.mic, color: Colors.grey[500], size: 22),
        ],
      ),
    );
  }

  /// A geocoded search result list item
  Widget _buildSearchResultItem(GeocodedPlace place, bool dark) {
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final dividerColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.location_on, color: AppColors.primaryBlue, size: 20),
          ),
          title: Text(
            place.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${place.latLng.latitude.toStringAsFixed(4)}, ${place.latLng.longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          trailing: Icon(
            Icons.north_east,
            color: dark ? Colors.grey[600] : Colors.grey[400],
            size: 18,
          ),
          onTap: () {
            // Return the selected place back to the previous screen
            Navigator.pop(context, place);
          },
        ),
        Divider(height: 1, color: dividerColor, indent: 72),
      ],
    );
  }

  /// A single recent location list item
  Widget _buildRecentItem(RecentLocation location, bool dark) {
    final titleColor = dark ? Colors.white : Colors.black;
    final subColor = dark ? Colors.grey[500]! : Colors.grey[600]!;
    final iconBg = dark
        ? AppColors.brandYellow.withValues(alpha: 0.15)
        : AppColors.brandYellow.withValues(alpha: 0.1);
    final dividerColor = dark ? Colors.grey[800]! : Colors.grey[200]!;

    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(Icons.history, color: AppColors.brandYellow, size: 20),
          ),
          title: Text(
            location.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
          subtitle: Text(
            location.subtitle,
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          trailing: Icon(
            Icons.north_east,
            color: dark ? Colors.grey[600] : Colors.grey[400],
            size: 18,
          ),
          onTap: () {
            // TODO: Select this location
          },
        ),
        Divider(height: 1, color: dividerColor, indent: 72),
      ],
    );
  }
}
