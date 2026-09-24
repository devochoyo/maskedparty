import 'package:flutter/material.dart';

class CallWarningDialog extends StatelessWidget {
  const CallWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 8 : 16,
        vertical: 16,
      ),
      child: Container(
        width: isLargeScreen ? 480 : double.infinity,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.75,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with warning icon
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isSmallScreen ? 12 : 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE91E63), Color(0xFFFF6B8B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Notice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 15 : 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Please read carefully before proceeding',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: isSmallScreen ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content - Scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Internet Connection
                    _buildWarningItem(
                      icon: Icons.wifi,
                      title: 'Stable Internet Connection',
                      description: 'Ensure a stable internet connection before starting the call. Ending the call before the minute elapses leads to loss of coins, so ensure your connection is stable.',
                      color: const Color(0xFF2196F3),
                      isSmallScreen: isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    
                    // Call Extensions
                    _buildWarningItem(
                      icon: Icons.add_circle_outline,
                      title: 'Call Extensions',
                      description: 'You can extend the call for more minutes while on video call if you need additional time.',
                      color: const Color(0xFF9C27B0),
                      isSmallScreen: isSmallScreen,
                    ),
                    const SizedBox(height: 12),
                    
                    // Rating Impact
                    _buildWarningItem(
                      icon: Icons.star,
                      title: 'Rating Impact',
                      description: '3 bad ratings from influencers will lead to suspension of your account and loss of funds.',
                      color: Colors.amber,
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 38 : 42,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: Text(
                                'Dismiss',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 38 : 42,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C853),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline, 
                                    size: isSmallScreen ? 14 : 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'I Agree',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: color, 
            size: isSmallScreen ? 18 : 20,
          ),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1D2E),
                ),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}