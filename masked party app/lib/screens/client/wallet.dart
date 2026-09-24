// FILE LOCATION: lib/screens/client/wallet.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/wallet_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'buy_coins.dart';
import 'transaction_history.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();

  dynamic _balanceData;
  List<dynamic> _recentHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
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

      final results = await Future.wait([
        _walletService.getBalance(token),
        _walletService.getHistory(token, limit: 5),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (!mounted) return;

      final balanceResult = results[0];
      final historyResult = results[1];

      setState(() {
        _isLoading = false;
        
        // Parse balance
        if (balanceResult is Map && balanceResult['success'] == true) {
          _balanceData = balanceResult['data'];
        } else {
          _error = (balanceResult is Map ? balanceResult['message'] : null) ?? 'Failed to load wallet';
        }
        
        // Parse history
        if (historyResult is Map && historyResult['success'] == true) {
          final data = historyResult['data'];
          if (data is List) {
            _recentHistory = data;
          } else if (data is Map && data['transactions'] is List) {
            _recentHistory = data['transactions'];
          } else if (data is Map && data['history'] is List) {
            _recentHistory = data['history'];
          } else if (data is Map && data['data'] is List) {
            _recentHistory = data['data'];
          } else {
            _recentHistory = [];
          }
        } else {
          _recentHistory = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _recentHistory = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _balance() {
    final raw = _balanceData is Map ? _balanceData['current_balance'] : null;
    if (raw is num) return raw.toDouble();
    return 0.0;
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
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Wallet',
          style: TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded, color: Color(0xFFE91E63), size: 22),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BuyCoinsScreen()),
                );
                _loadAll();
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : RefreshIndicator(
              onRefresh: _loadAll,
              color: const Color(0xFFE91E63),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Balance Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D63), Color(0xFFFF6B8B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Coins',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _balance().toStringAsFixed(
                                        _balance().truncateToDouble() == _balance()
                                            ? 0
                                            : 2),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Coins',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 32,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => BuyCoinsScreen()),
                                    );
                                    _loadAll();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFE91E63),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Buy Coins',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.monetization_on, color: Colors.amberAccent, size: 32),
                          ),
                        ],
                      ),
                    ),

                    // Quick Stats
                    if (_balanceData is Map && (_balanceData['total_spent'] != null || _balanceData['total_purchased'] != null)) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.call_made_rounded,
                              label: 'Total Spent',
                              value: '${_balanceData['total_spent'] ?? 0}',
                              color: const Color(0xFFFF2D63),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_cart_rounded,
                              label: 'Total Purchased',
                              value: '${_balanceData['total_purchased'] ?? 0}',
                              color: const Color(0xFF00C853),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1D2E),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
                                color: Color(0xFFE91E63),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Transactions List
                    if (_recentHistory.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        width: double.infinity,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE91E63).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                color: Color(0xFFE91E63),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < _recentHistory.length; i++) ...[
                              _buildTransactionItem(_recentHistory[i]),
                              if (i != _recentHistory.length - 1)
                                Divider(height: 1, indent: 60, endIndent: 16, color: Colors.grey.shade100),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    if (tx is! Map) return const SizedBox.shrink();

    final type = tx['type']?.toString() ?? '';
    final isCredit = type == 'purchase' || type == 'credit' || type == 'refund' 
        || type == 'coin_purchase' || type == 'wallet_funding'
        || type == 'escrow_release' || type == 'received';
    
    final coinsRaw = tx['coins'];
    final amountRaw = tx['amount'];
    
    // Parse values (API returns strings)
    int coins = 0;
    if (coinsRaw is int) {
      coins = coinsRaw.abs();
    } else if (coinsRaw is double) {
      coins = coinsRaw.abs().toInt();
    } else if (coinsRaw is String) {
      coins = (int.tryParse(coinsRaw) ?? double.tryParse(coinsRaw)?.toInt() ?? 0).abs();
    }
    
    double amount = 0.0;
    if (amountRaw is double) {
      amount = amountRaw.abs();
    } else if (amountRaw is int) {
      amount = amountRaw.abs().toDouble();
    } else if (amountRaw is String) {
      amount = (double.tryParse(amountRaw) ?? 0.0).abs();
    }
    
    final description = tx['description']?.toString() ?? (isCredit ? 'Coins purchased' : 'Coins spent');
    final date = tx['created_at']?.toString() ?? tx['date']?.toString() ?? '';
    final status = tx['status']?.toString() ?? (isCredit ? 'Successful' : 'Completed');

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

    final IconData transactionIcon = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    // Determine what to show
    final String displayValue;
    if (coins > 0) {
      displayValue = '${isCredit ? '+' : '-'}$coins Coins';
    } else if (amount > 0) {
      displayValue = '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)}';
    } else {
      displayValue = '0 Coins';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFF00C853).withOpacity(0.1)
                  : const Color(0xFFFF2D63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              transactionIcon,
              color: isCredit ? const Color(0xFF00C853) : const Color(0xFFFF2D63),
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
                    color: Color(0xFF1A1D2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$displayDate • $status',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isCredit ? const Color(0xFF00C853) : const Color(0xFFFF2D63),
            ),
          ),
        ],
      ),
    );
  }
}