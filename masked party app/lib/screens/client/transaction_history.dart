// FILE LOCATION: lib/screens/client/transaction_history.dart
import 'package:flutter/material.dart';
import 'package:maskedparty/services/wallet_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = WalletService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;

  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
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
      
      final result = await _walletService.getHistory(token, limit: 100).timeout(
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
            _transactions = data;
          } else if (data is Map && data['transactions'] is List) {
            _transactions = data['transactions'];
          } else if (data is Map && data['history'] is List) {
            _transactions = data['history'];
          } else if (data is Map && data['data'] is List) {
            _transactions = data['data'];
          } else {
            _transactions = [];
          }
          _error = null;
        } else {
          _transactions = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load transactions';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _transactions = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<dynamic> get _filteredTransactions {
    if (_filter == 'all') return _transactions;
    return _transactions.where((tx) {
      if (tx is! Map) return false;
      final type = tx['type']?.toString() ?? '';
      final isCredit = type == 'purchase' || type == 'credit' || type == 'refund' 
          || type == 'coin_purchase' || type == 'wallet_funding';
      return _filter == 'purchase' ? isCredit : !isCredit;
    }).toList();
  }

  void _showFilterMenu() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Filter Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E),
                    ),
                  ),
                ),
              ),
              _buildFilterOption(
                icon: Icons.list_rounded,
                title: 'All Transactions',
                value: 'all',
                isSelected: _filter == 'all',
              ),
              _buildFilterOption(
                icon: Icons.shopping_cart_rounded,
                title: 'Purchases Only',
                value: 'purchase',
                isSelected: _filter == 'purchase',
              ),
              _buildFilterOption(
                icon: Icons.phone_in_talk_rounded,
                title: 'Call Spend Only',
                value: 'spend',
                isSelected: _filter == 'spend',
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (selected != null) setState(() => _filter = selected);
  }

  Widget _buildFilterOption({
    required IconData icon,
    required String title,
    required String value,
    required bool isSelected,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE91E63).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFE91E63) : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? const Color(0xFFE91E63) : Colors.black87,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFFE91E63), size: 20)
          : null,
      onTap: () => Navigator.pop(context, value),
    );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1D2E), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: _showFilterMenu,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list_rounded, color: Color(0xFFE91E63), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _filter == 'all' ? 'All' : (_filter == 'purchase' ? 'Purchases' : 'Spend'),
                      style: const TextStyle(
                        color: Color(0xFFE91E63),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFE91E63), size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
            : _error != null
                ? _buildErrorState()
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        color: const Color(0xFFE91E63),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final isFirst = index == 0;
                            final tx = _filteredTransactions[index];
                            final showDateHeader = isFirst || _shouldShowDateHeader(index);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDateHeader) ...[
                                  if (!isFirst) const SizedBox(height: 16),
                                  _buildDateHeader(tx),
                                  const SizedBox(height: 8),
                                ],
                                _buildTransactionCard(tx),
                                const SizedBox(height: 8),
                              ],
                            );
                          },
                        ),
                      ),
      ),
    ),
      ),
    );
  }

  bool _shouldShowDateHeader(int index) {
    if (index == 0) return true;
    final currentTx = _filteredTransactions[index];
    final previousTx = _filteredTransactions[index - 1];
    
    final currentDate = _getTransactionDate(currentTx);
    final previousDate = _getTransactionDate(previousTx);
    
    return currentDate != previousDate;
  }

  String _getTransactionDate(dynamic tx) {
    if (tx is! Map) return '';
    final date = tx['created_at']?.toString() ?? tx['date']?.toString() ?? '';
    if (date.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(date);
      return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildDateHeader(dynamic tx) {
    if (tx is! Map) return const SizedBox.shrink();
    final date = tx['created_at']?.toString() ?? tx['date']?.toString() ?? '';
    
    String displayDate = '';
    if (date.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(date);
        final now = DateTime.now();
        final difference = now.difference(dateTime);
        
        if (difference.inDays == 0) {
          displayDate = 'Today';
        } else if (difference.inDays == 1) {
          displayDate = 'Yesterday';
        } else if (difference.inDays < 7) {
          final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
          displayDate = days[dateTime.weekday - 1];
        } else {
          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          displayDate = '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
        }
      } catch (e) {
        displayDate = date;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        displayDate,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A1D2E),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
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

    String displayTime = '';
    if (date.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(date);
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        displayTime = '$hour:$minute';
      } catch (e) {
        displayTime = date;
      }
    }

    final IconData transactionIcon = isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final String displayValue;
    final String displayLabel;
    
    if (coins > 0) {
      displayValue = '${isCredit ? '+' : '-'}$coins';
      displayLabel = 'Coins';
    } else if (amount > 0) {
      displayValue = '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)}';
      displayLabel = 'Amount';
    } else {
      displayValue = '0';
      displayLabel = 'Coins';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit
                    ? const Color(0xFF00C853).withOpacity(0.1)
                    : const Color(0xFFFF2D63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transactionIcon,
                color: isCredit ? const Color(0xFF00C853) : const Color(0xFFFF2D63),
                size: 20,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1D2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        displayTime,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'Successful' || status == 'Completed'
                              ? const Color(0xFF00C853).withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: status == 'Successful' || status == 'Completed'
                                ? const Color(0xFF00C853)
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  displayValue,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? const Color(0xFF00C853) : const Color(0xFFFF2D63),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayLabel,
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, color: Color(0xFFE91E63), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _filter != 'all'
                  ? 'No ${_filter == 'purchase' ? 'purchases' : 'spends'} found'
                  : 'Your transactions will appear here',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}