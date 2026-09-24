// FILE LOCATION: lib/screens/shared/referrals.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maskedparty/services/referral_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralService _referralService = ReferralService();
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<String, dynamic>? _referralData;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _referralService.getMyReferralCode();
      if (mounted) {
        setState(() {
          _referralData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyReferralCode() {
    if (_referralData == null) return;
    
    final code = _referralData!['referral_code'] ?? '';
    if (code.isEmpty) return;

    Clipboard.setData(ClipboardData(text: code));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral code "$code" copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    
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
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1D2E), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Referrals',
          style: TextStyle(
            color: const Color(0xFF1A1D2E),
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE91E63),
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: isSmallScreen ? 40 : 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Text(
                          'Failed to load referral data',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: isSmallScreen ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        TextButton(
                          onPressed: _loadReferralData,
                          child: Text(
                            'Retry',
                            style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.all(horizontalPadding),
                      children: [
                        // Referral Code Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC2185B), Color(0xFFE91E63)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC2185B).withValues(alpha: 0.4),
                                blurRadius: isSmallScreen ? 15 : 20,
                                offset: Offset(0, isSmallScreen ? 6 : 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 36 : 48,
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Text(
                                'Your Referral Code',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 12),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 16 : 24,
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _referralData?['referral_code'] ?? '------',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: isSmallScreen ? 22 : 28,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: isSmallScreen ? 2 : 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isSmallScreen ? 8 : 12),
                                    InkWell(
                                      onTap: _copyReferralCode,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          color: Colors.white,
                                          size: isSmallScreen ? 18 : 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              Text(
                                'Share this code with friends and earn 5% commission on their first deposit!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 11 : 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Stats Cards
                        _buildStatsGrid(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 16 : 24),

                        // Commission Info Card
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
                                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE91E63).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Color(0xFFE91E63),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 8 : 12),
                                  Text(
                                    'How it Works',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1D2E),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildInfoRow(
                                '1',
                                'Share your referral code with friends',
                                isSmallScreen,
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 12),
                              _buildInfoRow(
                                '2',
                                'They sign up using your code',
                                isSmallScreen,
                              ),
                              SizedBox(height: isSmallScreen ? 10 : 12),
                              _buildInfoRow(
                                '3',
                                'You earn ${((_referralData?['commission_rate'] ?? 0.05) * 100).toStringAsFixed(0)}% commission on their first deposit',
                                isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 24 : 32),
                      ],
                    );
                  },
                ),
    ),
      ),
    );
  }

  Widget _buildStatsGrid(bool isSmallScreen) {
    final stats = [
      {
        'icon': Icons.people_rounded,
        'title': 'Total Referred',
        'value': '${_referralData?['total_referred'] ?? 0}',
        'color': Colors.blue,
      },
      {
        'icon': Icons.check_circle_rounded,
        'title': 'Converted',
        'value': '${_referralData?['total_converted'] ?? 0}',
        'color': Colors.green,
      },
      {
        'icon': Icons.hourglass_empty_rounded,
        'title': 'Pending',
        'value': '${_referralData?['pending_referrals'] ?? 0}',
        'color': Colors.orange,
      },
      {
        'icon': Icons.monetization_on_rounded,
        'title': 'Coins Earned',
        'value': '${_referralData?['total_earned_coins']?.toString() ?? '0'}',
        'color': const Color(0xFFE91E63),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: isSmallScreen ? 8 : 12,
        mainAxisSpacing: isSmallScreen ? 8 : 12,
        childAspectRatio: isSmallScreen ? 1.3 : 1.2,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(
          icon: stat['icon'] as IconData,
          title: stat['title'] as String,
          value: stat['value'] as String,
          color: stat['color'] as Color,
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1D2E),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 10 : 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String number, String text, bool isSmallScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isSmallScreen ? 20 : 24,
          height: isSmallScreen ? 20 : 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: const Color(0xFF1A1D2E),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}