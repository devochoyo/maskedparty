// FILE LOCATION: lib/screens/client/save.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maskedparty/services/client_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'influencer_details.dart';

class SavedInfluencersScreen extends StatefulWidget {
  const SavedInfluencersScreen({super.key});

  @override
  State<SavedInfluencersScreen> createState() => _SavedInfluencersScreenState();
}

class _SavedInfluencersScreenState extends State<SavedInfluencersScreen> {
  final ClientService _clientService = ClientService();
  List<dynamic> _saved = [];
  bool _isLoading = true;
  String? _error;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _darkPink = Color(0xFFC2185B);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _onlineGreen = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      
      final result = await _clientService.getSavedInfluencers(token).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is List) {
            _saved = data;
          } else if (data is Map && data['influencers'] is List) {
            _saved = data['influencers'];
          } else if (data is Map && data['saved'] is List) {
            _saved = data['saved'];
          } else if (data is Map && data['data'] is List) {
            _saved = data['data'];
          } else {
            _saved = [];
          }
          _error = null;
        } else {
          _saved = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load saved influencers';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _saved = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _unsave(String influencerId) async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    
    try {
      final result = await _clientService.removeSavedInfluencer(token, influencerId).timeout(
        const Duration(seconds: 10),
      );
      
      if (!mounted) return;
      
      if (result is Map && result['success'] == true) {
        setState(() {
          _saved.removeWhere((inf) => inf is Map && inf['id']?.toString() == influencerId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Removed from saved'),
            backgroundColor: _primaryPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: isSmallScreen
            ? const TextScaler.linear(0.92)
            : MediaQuery.of(context).textScaler,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: isSmallScreen
              ? VisualDensity.compact
              : Theme.of(context).visualDensity,
        ),
        child: Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: _textDark, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Saved Influencers',
          style: TextStyle(
            color: _textDark,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryPink, _softPink],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 3,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _saved.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadSaved,
                      color: _primaryPink,
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _saved.length,
                        itemBuilder: (context, index) => _buildCard(_saved[index]),
                      ),
                    ),
    ),
      ),
    );
  }

  Widget _buildCard(dynamic inf) {
    if (inf is! Map) return const SizedBox.shrink();
    
    final id = inf['id']?.toString() ?? '';
    final name = inf['mystery_name']?.toString() ?? 'Unknown';
    final photo = inf['profile_photo']?.toString();
    final country = inf['country_name']?.toString();
    final isOnline = inf['online_status'] == 'online' ||
        inf['online_status'] == 1 ||
        inf['online_status'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => InfluencerDetailsScreen(influencerId: id)),
          ).then((_) => _loadSaved()),
          borderRadius: BorderRadius.circular(20),
          splashColor: _primaryPink.withValues(alpha: 0.08),
          highlightColor: _primaryPink.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _lightPink.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _primaryPink.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile photo with gradient border
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryPink, _softPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: photo != null && photo.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: photo,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: _lightPink,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _primaryPink,
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: _lightPink,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 30,
                                    color: _primaryPink.withValues(alpha: 0.5),
                                  ),
                                ),
                              )
                            : Container(
                                color: _lightPink,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 30,
                                  color: _primaryPink.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _onlineGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _onlineGreen.withValues(alpha: 0.4),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Name and country
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: _textDark,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (country != null && country.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: _primaryPink.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: _primaryPink,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                country,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textMedium,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Unsave button with gradient
                GestureDetector(
                  onTap: () => _unsave(id),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primaryPink, _softPink],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPink.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.bookmark_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(fontSize: 14, color: _textMedium),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _loadSaved,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No saved Influencers',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bookmark creators to see them here',
              style: TextStyle(
                fontSize: 14,
                color: _textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}