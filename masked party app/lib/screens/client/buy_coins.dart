// FILE LOCATION: lib/screens/client/buy_coins.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:maskedparty/services/coin_package_service.dart';
import 'package:maskedparty/services/payment_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class BuyCoinsScreen extends StatefulWidget {
  const BuyCoinsScreen({super.key});

  @override
  State<BuyCoinsScreen> createState() => _BuyCoinsScreenState();
}

class _BuyCoinsScreenState extends State<BuyCoinsScreen> {
  final CoinPackageService _packageService = CoinPackageService();
  final PaymentService _paymentService = PaymentService();

  List<dynamic> _packages = [];
  bool _isLoading = true;
  String? _error;
  String? _payingPackageId;

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
  static const Color _warningOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
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
      
      final result = await _packageService.getPackages(token).timeout(
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
            _packages = data;
          } else if (data is Map && data['packages'] is List) {
            _packages = data['packages'];
          } else {
            _packages = [];
          }
          _error = null;
        } else {
          _packages = [];
          _error = (result is Map ? result['message'] : null) ?? 'Failed to load coin packages';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _packages = [];
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _buyPackage(dynamic pkg) async {
    if (pkg is! Map) return;
    
    if (_payingPackageId != null) return;
    
    final packageId = pkg['package_id']?.toString();
    if (packageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Invalid package'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _payingPackageId = packageId);

    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        setState(() => _payingPackageId = null);
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }

      // STEP 1: Create payment on backend
      final createResult = await _paymentService.createPayment(token, packageId).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Payment request timed out');
        },
      );

      if (!mounted) return;

      if (createResult is! Map || createResult['success'] != true) {
        setState(() => _payingPackageId = null);
        final message = createResult is Map ? createResult['message'] : null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Failed to start payment'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      final data = createResult['data'] as Map<String, dynamic>;
      final authorizationUrl = data['authorization_url']?.toString();
      final reference = data['reference']?.toString();

      if (authorizationUrl == null || reference == null) {
        setState(() => _payingPackageId = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment server error. Missing URL or reference.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        return;
      }

      setState(() => _payingPackageId = null);

      // STEP 2: Open Flutterwave Standard checkout in WebView
      if (mounted) {
        final paymentSuccess = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlutterwaveCheckoutScreen(
              authorizationUrl: authorizationUrl,
              reference: reference,
            ),
          ),
        );

        // STEP 3: Verify payment when returning from WebView
        if (paymentSuccess == true && mounted) {
          await _verifyPayment(token, reference);
        }
      }
    } catch (e) {
      setState(() => _payingPackageId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _verifyPayment(String token, String reference) async {
    try {
      final verifyResult = await _paymentService.verifyPayment(token, reference).timeout(
        const Duration(seconds: 30),
      );

      if (!mounted) return;

      if (verifyResult is Map && verifyResult['success'] == true) {
        final data = verifyResult['data'];
        final walletBalance = data?['wallet_balance']?.toString() ?? '0';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! Balance: $walletBalance coins'),
            backgroundColor: _successGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        Navigator.pop(context);
      } else {
        final statusCode = verifyResult is Map ? verifyResult['status_code'] : null;
        final message = verifyResult is Map ? verifyResult['message'] : null;

        if (statusCode == 409) {
          // Already processed via webhook — treat as success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Payment was processed successfully!'),
              backgroundColor: _successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          Navigator.pop(context);
        } else if (statusCode == 502) {
          // Flutterwave unreachable — retry after delay
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Verifying payment... Please wait.'),
              backgroundColor: _warningOrange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          await Future.delayed(const Duration(seconds: 5));
          if (mounted) {
            final retryToken = await SessionManager.getToken();
            if (retryToken != null) {
              await _verifyPayment(retryToken, reference);
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Verification failed. Please contact support.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Network error during verification. Please check your balance.'),
            backgroundColor: _warningOrange,
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
          'Buy Coins',
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
          : _error != null
              ? _buildErrorState()
              : _packages.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPackages,
                      color: _primaryPink,
                      backgroundColor: Colors.white,
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Enhanced hero card
                          Container(
                            width: double.infinity,
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
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.diamond_outlined,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Get More Coins',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Choose a package to continue',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Section header with icon
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _primaryPink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.local_offer_rounded,
                                  color: _primaryPink,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Select Package',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._packages.map((pkg) => _buildPackageCard(pkg)),
                        ],
                      ),
                    ),
    ),
      ),
    );
  }

  Widget _buildPackageCard(dynamic pkg) {
    if (pkg is! Map) return const SizedBox.shrink();
    
    final packageId = pkg['package_id']?.toString() ?? '';
    final isBestValue = pkg['is_best_value'] == true;
    final isPaying = _payingPackageId != null && _payingPackageId == packageId;
    final coins = pkg['coins']?.toString() ?? '0';
    final price = pkg['price']?.toString() ?? '0';
    final packageName = pkg['package_name']?.toString() ?? '';

    final priceNum = double.tryParse(price) ?? 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBestValue ? _primaryPink : _lightPink.withValues(alpha: 0.4),
          width: isBestValue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isBestValue
                ? _primaryPink.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isPaying ? null : () => _buyPackage(pkg),
          borderRadius: BorderRadius.circular(20),
          splashColor: _primaryPink.withValues(alpha: 0.05),
          highlightColor: _primaryPink.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Coin icon with enhanced design
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _primaryPink.withValues(alpha: 0.12),
                        _softPink.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _primaryPink.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.monetization_on_rounded,
                    color: _primaryPink,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                // Package info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$coins coins',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isBestValue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryPink, _softPink],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryPink.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '£${priceNum.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: isBestValue ? _primaryPink : _textMedium,
                          fontWeight: isBestValue ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Buy button
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isPaying ? null : () => _buyPackage(pkg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBestValue ? _primaryPink : Colors.white,
                      foregroundColor: isBestValue ? Colors.white : _primaryPink,
                      elevation: isBestValue ? 2 : 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      side: isBestValue ? null : BorderSide(color: _primaryPink.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: isBestValue ? _primaryPink.withValues(alpha: 0.3) : null,
                    ),
                    child: isPaying
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isBestValue ? Colors.white : _primaryPink,
                            ),
                          )
                        : const Text(
                            'Buy',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
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
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
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
              style: const TextStyle(color: _textMedium, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPackages,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
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
              padding: const EdgeInsets.all(24),
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
                border: Border.all(
                  color: _primaryPink.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: _primaryPink, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No packages available',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check back later for coin packages',
              style: TextStyle(fontSize: 14, color: _textMedium),
            ),
          ],
        ),
      ),
    );
  }
}

// Separate screen for Flutterwave Standard WebView checkout
class FlutterwaveCheckoutScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const FlutterwaveCheckoutScreen({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  @override
  State<FlutterwaveCheckoutScreen> createState() => _FlutterwaveCheckoutScreenState();
}

class _FlutterwaveCheckoutScreenState extends State<FlutterwaveCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  static const Color _primaryPink = Color(0xFFE91E63);
  static const Color _textDark = Color(0xFF1A1D2E);
  static const Color _lightPink = Color(0xFFFFE4EC);

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            
            if (!_paymentCompleted && _isPaymentSuccessUrl(url)) {
              _paymentCompleted = true;
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            }
          },
          onUrlChange: (change) {
            final url = change.url ?? '';
            if (!_paymentCompleted && _isPaymentSuccessUrl(url)) {
              _paymentCompleted = true;
              Future.delayed(const Duration(milliseconds: 800), () {
                if (mounted) {
                  Navigator.pop(context, true);
                }
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }


  bool _isPaymentSuccessUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // Flutterwave redirect: status=successful&tx_ref=...
    final status = uri.queryParameters['status']?.toLowerCase();
    if (status == 'successful' || status == 'completed') return true;
    // Also accept our reference appearing on success/redirect pages
    if (url.contains(widget.reference) &&
        (url.contains('successful') ||
         url.contains('status=successful') ||
         url.contains('verify-payment'))) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: _textDark),
          onPressed: () {
            if (!_paymentCompleted) {
              Navigator.pop(context, false);
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              color: _primaryPink,
              size: 18,
            ),
            SizedBox(width: 6),
            Text(
              'Secure Checkout',
              style: TextStyle(
                color: _textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
          ],
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(
                  color: _primaryPink,
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }
}