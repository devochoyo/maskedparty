// FILE LOCATION: lib/screens/influencer/earnings.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/influencer_service.dart';
import 'package:maskedparty/services/wallet_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'withdrawal.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  final InfluencerService _influencerService = InfluencerService();
  final WalletService _walletService = WalletService();

  int _selectedTabIndex = 0; // 0 Today, 1 This Week, 2 This Month

  Map<String, dynamic>? _earnings;
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _errorMessage;

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
  static const Color _dangerRed = Color(0xFFFF2D63);
  static const Color _infoBlue = Color(0xFF2196F3);
  static const Color _goldAmber = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }

      final results = await Future.wait([
        _influencerService.getEarnings(token),
        _walletService.getHistory(token, limit: 20),
      ]).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final earningsResult = results[0];
      final historyResult = results[1];

      setState(() {
        _isLoading = false;
        if (earningsResult is Map && earningsResult['success'] == true) {
          _earnings = Map<String, dynamic>.from(earningsResult['data'] ?? {});
        } else {
          _errorMessage = (earningsResult is Map ? earningsResult['message'] : null) ??
              'Failed to load earnings';
        }
        if (historyResult is Map && historyResult['success'] == true) {
          final raw = historyResult['data'];
          final list = raw is Map ? raw['history'] ?? raw['transactions'] ?? [] : raw;
          _history = (list is List) ? list : [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  num _periodValue(String key) {
    if (_earnings == null) return 0;
    final v = _earnings![key];
    if (v is num) return v;
    return num.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _periodEarningsKey() {
    switch (_selectedTabIndex) {
      case 1:
        return 'this_week_earnings';
      case 2:
        return 'this_month_earnings';
      default:
        return 'today_earnings';
    }
  }

  String _periodCallsKey() {
    switch (_selectedTabIndex) {
      case 1:
        return 'this_week_calls';
      case 2:
        return 'this_month_calls';
      default:
        return 'today_calls';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final availableBalance = _periodValue('wallet_balance') != 0
        ? _periodValue('wallet_balance')
        : _periodValue('available_balance');

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
          'Earnings',
          style: TextStyle(
            color: _textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: _lightPink.withValues(alpha: 0.3),
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
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _primaryPink,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withValues(alpha: 0.08),
                              Colors.red.withValues(alpha: 0.04),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Balance Card with enhanced design
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryPink, _softPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryPink.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Available Balance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.monetization_on_rounded,
                                  color: _goldAmber,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                availableBalance.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 9),
                                child: Text(
                                  'Coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WithdrawalScreen(),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryPink,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.account_balance_wallet_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Withdraw',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Period Tabs with enhanced design
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(18),
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
                      child: Row(
                        children: [
                          Expanded(child: _buildTabButton('Today', 0)),
                          Expanded(child: _buildTabButton('This Week', 1)),
                          Expanded(child: _buildTabButton('This Month', 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Statistics Section
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
                            Icons.bar_chart_rounded,
                            size: 16,
                            color: _primaryPink,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Statistics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.phone_in_talk_rounded,
                            'Calls',
                            _periodValue(_periodCallsKey()).toString(),
                            _primaryPink,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: _lightPink.withValues(alpha: 0.3),
                          ),
                          _buildStatItem(
                            Icons.monetization_on_rounded,
                            'Earnings',
                            _periodValue(_periodEarningsKey()).toStringAsFixed(0),
                            _successGreen,
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: _lightPink.withValues(alpha: 0.3),
                          ),
                          _buildStatItem(
                            Icons.trending_up_rounded,
                            'Lifetime',
                            _periodValue('lifetime_earnings').toStringAsFixed(0),
                            _infoBlue,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Transactions Section
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
                            Icons.receipt_long_rounded,
                            size: 16,
                            color: _primaryPink,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _lightPink.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    _primaryPink.withValues(alpha: 0.1),
                                    _softPink.withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: _primaryPink.withValues(alpha: 0.6),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: _textMedium,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
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
                          children: [
                            for (var i = 0; i < _history.length; i++) ...[
                              _buildTransactionItem(_history[i]),
                              if (i != _history.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 60,
                                  endIndent: 16,
                                  color: _lightPink.withValues(alpha: 0.3),
                                ),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : _textMedium,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
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

  Widget _buildTransactionItem(dynamic item) {
    if (item is! Map) return const SizedBox.shrink();
    
    final description = item['description']?.toString() ?? item['type']?.toString() ?? 'Transaction';
    final coins = item['coins'];
    final amount = item['amount'];
    final date = item['created_at']?.toString() ?? item['date']?.toString() ?? '';
    final amountNum = amount is num ? amount : num.tryParse(amount?.toString() ?? '') ?? 0;
    final isCredit = amountNum >= 0;

    String displayDate = '';
    if (date.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(date);
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        if (difference.inDays > 7) {
          displayDate = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
        } else if (difference.inDays > 0) {
          displayDate = '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          displayDate = '${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          displayDate = '${difference.inMinutes}m ago';
        } else {
          displayDate = 'Just now';
        }
      } catch (e) {
        displayDate = date;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (isCredit ? _successGreen : _dangerRed).withValues(alpha: 0.12),
                  (isCredit ? _successGreen : _dangerRed).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isCredit ? _successGreen : _dangerRed).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? _successGreen : _dangerRed,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isCredit ? _successGreen : _dangerRed).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${isCredit ? '+' : '-'}${amountNum.toStringAsFixed(0)} Coins',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCredit ? _successGreen : _dangerRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}