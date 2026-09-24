import 'package:flutter/material.dart';
import 'home.dart';
import 'chat.dart';
import 'profile.dart';
import 'followers.dart';
import 'create_post.dart';

class InfluencerBottomNavigation extends StatefulWidget {
  const InfluencerBottomNavigation({super.key});

  @override
  State<InfluencerBottomNavigation> createState() =>
      _InfluencerBottomNavigationState();
}

class _InfluencerBottomNavigationState
    extends State<InfluencerBottomNavigation> {
  int _currentIndex = 0;

  // Color palette
  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _softPink = Color(0xFFFF6B8B);
  static const Color _lightPink = Color(0xFFFFE4EC);
  static const Color _darkPink = Color(0xFFC2185B);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _textLight = Color(0xFF9CA3AF);

  void _goToTab(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _screens = [
    const InfluencerHomeScreen(),
    const InfluencerChatScreen(),
    const SizedBox.shrink(), // placeholder for Create (center button)
    const InfluencerFollowersScreen(),
    const InfluencerProfileScreen(),
  ];

  Future<void> _openCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (result == true && mounted) {
      // optionally refresh home
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive calculations
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
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              _lightPink.withValues(alpha: 0.3),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _primaryPink.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          border: Border(
            top: BorderSide(
              color: _primaryPink.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 4 : 8, 
              vertical: isSmallScreen ? 4 : 8
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    index: 1,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                // Center Create button with responsive sizing
                GestureDetector(
                  onTap: _openCreatePost,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isSmallScreen ? 48 : 56,
                          height: isSmallScreen ? 48 : 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [_primaryPink, _darkPink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryPink.withValues(alpha: 0.4),
                                blurRadius: isSmallScreen ? 12 : 16,
                                offset: Offset(0, isSmallScreen ? 4 : 6),
                              ),
                              BoxShadow(
                                color: _softPink.withValues(alpha: 0.2),
                                blurRadius: isSmallScreen ? 6 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: isSmallScreen ? 26 : 30,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          'Create',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 8 : 10,
                            fontWeight: FontWeight.w700,
                            color: _primaryPink,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.people_outline_rounded,
                    activeIcon: Icons.people_rounded,
                    label: 'Followers',
                    index: 3,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Profile',
                    index: 4,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isSmallScreen,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _goToTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 4 : 8, 
          vertical: isSmallScreen ? 4 : 6
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.12),
                    _softPink.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
          border: isSelected
              ? Border.all(
                  color: _primaryPink.withValues(alpha: 0.2),
                  width: 1.5,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.1),
                    blurRadius: isSmallScreen ? 6 : 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated icon with scale effect
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? _primaryPink : _textLight,
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(height: isSmallScreen ? 2 : 3),
            // Label with animated color
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isSmallScreen ? 8 : 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _primaryPink : _textLight,
                letterSpacing: isSelected ? 0.3 : 0,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Active indicator dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(top: isSmallScreen ? 2 : 3),
              width: isSelected ? (isSmallScreen ? 12 : 16) : 0,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}