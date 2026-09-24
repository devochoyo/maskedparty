// FILE LOCATION: lib/screens/influencer/profile.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/auth_service.dart';
import 'package:maskedparty/services/profile_service.dart';
import 'package:maskedparty/services/influencer_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'edit_profile.dart';
import 'gallery.dart';
import 'verification.dart';
import 'package:maskedparty/screens/shared/referrals.dart';

class InfluencerProfileScreen extends StatefulWidget {
  const InfluencerProfileScreen({super.key});

  @override
  State<InfluencerProfileScreen> createState() => _InfluencerProfileScreenState();
}

class _InfluencerProfileScreenState extends State<InfluencerProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final InfluencerService _influencerService = InfluencerService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _profile;
  num _lifetimeCalls = 0;
  bool _isLoading = true;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _bgColor = Color(0xFFF8F9FE);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textMedium = Color(0xFF6B7280);
  static const Color _textLight = Color(0xFF9CA3AF);
  static const Color _successGreen = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }

      final results = await Future.wait([
        _profileService.getProfile(token),
        _influencerService.getEarnings(token),
      ]).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final profileResult = results[0];
      final earningsResult = results[1];

      setState(() {
        _isLoading = false;
        if (profileResult is Map && profileResult['success'] == true) {
          _profile = Map<String, dynamic>.from(profileResult['data'] ?? {});
        }
        if (earningsResult is Map && earningsResult['success'] == true) {
          final data = earningsResult['data'] ?? {};
          final calls = data['lifetime_calls'] ?? data['total_calls'];
          _lifetimeCalls = calls is num ? calls : (num.tryParse(calls?.toString() ?? '') ?? 0);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: _primaryPink, size: 28),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            fontSize: 15,
            color: _textMedium,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final token = await SessionManager.getToken();
      if (token != null) {
        await _authService.logout(token);
      }
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final mysteryName = _profile?['mystery_name']?.toString() ?? 'Influencer';
    final biography = _profile?['biography']?.toString();
    final country = _profile?['country_name']?.toString() ?? _profile?['country']?.toString();
    final photo = _profile?['profile_photo']?.toString();
    final verified = _profile?['verification_status']?.toString() == 'verified' || _profile?['is_verified'] == true;
    final rating = _profile?['average_rating']?.toString() ?? '0.0';

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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 3,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primaryPink,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    // Header Section with enhanced design
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        bottom: 28,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _lightPink.withValues(alpha: 0.5),
                            Colors.white,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPink.withValues(alpha: 0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Back and Edit Buttons
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildHeaderButton(
                                  icon: Icons.arrow_back_rounded,
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                                _buildHeaderButton(
                                  icon: Icons.edit_outlined,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const InfluencerEditProfileScreen(),
                                    ),
                                  ).then((_) => _loadData()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Profile Photo with enhanced gradient border
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_primaryPink, _softPink, Color(0xFF7C4DFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(65),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryPink.withValues(alpha: 0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(61),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(58),
                                child: (photo != null && photo.isNotEmpty)
                                    ? Image.network(
                                        photo,
                                        height: 112,
                                        width: 112,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                                      )
                                    : _buildAvatarPlaceholder(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name with verification badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  mysteryName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _textDark,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (verified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: _successGreen.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_rounded,
                                    color: _successGreen,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (country != null && country.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryPink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _primaryPink.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: _primaryPink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    country,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _primaryPink,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Stats Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _lightPink.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryPink.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStatItem(
                                  icon: Icons.call_rounded,
                                  value: '$_lifetimeCalls',
                                  label: 'Calls',
                                  color: _primaryPink,
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  margin: const EdgeInsets.symmetric(horizontal: 24),
                                  color: _lightPink.withValues(alpha: 0.3),
                                ),
                                _buildStatItem(
                                  icon: Icons.star_rounded,
                                  value: rating,
                                  label: 'Rating',
                                  color: const Color(0xFFFFB300),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // About Section with enhanced design
                    if (biography != null && biography.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _lightPink.withValues(alpha: 0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          _primaryPink.withValues(alpha: 0.12),
                                          _softPink.withValues(alpha: 0.06),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _primaryPink.withValues(alpha: 0.15),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: _primaryPink,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'About Me',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                biography,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: _textMedium,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Menu Items with enhanced design (Settings removed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _cardColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _lightPink.withValues(alpha: 0.5),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryPink.withValues(alpha: 0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildMenuItem(
                                  icon: Icons.card_giftcard_rounded,
                                  title: 'Referrals',
                                  subtitle: 'Invite friends & earn rewards',
                                  iconBgColor: _primaryPink.withValues(alpha: 0.08),
                                  iconColor: _primaryPink,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ReferralScreen(),
                                    ),
                                  ),
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  icon: Icons.photo_library_outlined,
                                  title: 'Gallery',
                                  subtitle: 'Manage your photos',
                                  iconBgColor: Colors.blue.withValues(alpha: 0.08),
                                  iconColor: Colors.blue,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const GalleryScreen(),
                                    ),
                                  ),
                                ),
                                _buildDivider(),
                                _buildMenuItem(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Verification',
                                  subtitle: 'Verify your account',
                                  iconBgColor: _successGreen.withValues(alpha: 0.08),
                                  iconColor: _successGreen,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const VerificationScreen(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Logout Button with enhanced design
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  _lightPink.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _primaryPink.withValues(alpha: 0.15),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryPink.withValues(alpha: 0.08),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _primaryPink.withValues(alpha: 0.1),
                                      _softPink.withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.logout_rounded,
                                  color: _primaryPink,
                                  size: 24,
                                ),
                              ),
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  color: _primaryPink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: const Text(
                                'Sign out of your account',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textMedium,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryPink.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: _primaryPink,
                                  size: 14,
                                ),
                              ),
                              onTap: _logout,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: _primaryPink.withValues(alpha: 0.05),
        highlightColor: _primaryPink.withValues(alpha: 0.03),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _lightPink.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryPink.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _textDark, size: 20),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 20,
      color: _lightPink.withValues(alpha: 0.3),
      thickness: 0.5,
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      height: 112,
      width: 112,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _lightPink.withValues(alpha: 0.5),
            Colors.white,
          ],
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 55,
        color: _primaryPink.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: _primaryPink.withValues(alpha: 0.05),
        highlightColor: _primaryPink.withValues(alpha: 0.03),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: _textDark,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.withValues(alpha: 0.5),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}