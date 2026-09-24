import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:maskedparty/services/auth_service.dart';
import 'package:maskedparty/services/authentication_service.dart';
import 'package:maskedparty/services/profile_service.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/influencer_service.dart';
import 'package:maskedparty/services/wallet_service.dart';
import 'package:maskedparty/services/payg_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'package:maskedparty/services/api.dart';
import 'package:maskedparty/services/api_endpoints.dart';
import 'package:maskedparty/widgets/incoming_call_screen.dart';
import 'video_call.dart';
import 'notifications.dart';
import 'withdrawal.dart';
import 'complete_profile.dart';
import 'verification.dart';
import '../auth/otp_verification.dart';

class InfluencerHomeScreen extends StatefulWidget {
  final VoidCallback? onWalletTap;

  const InfluencerHomeScreen({super.key, this.onWalletTap});

  @override
  State<InfluencerHomeScreen> createState() => _InfluencerHomeScreenState();
}

class _InfluencerHomeScreenState extends State<InfluencerHomeScreen> {
  final AuthService _authService = AuthService();
  final AuthenticationService _authenticationService = AuthenticationService();
  final ProfileService _profileService = ProfileService();
  final CallService _callService = CallService();
  final InfluencerService _influencerService = InfluencerService();
  final WalletService _walletService = WalletService();
  final PaygService _paygService = PaygService();

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _earnings;
  num _walletBalance = 0;
  List<dynamic> _recentActivities = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isOnline = false;
  bool _isTogglingOnline = false;
  bool _whatOfferPromptShown = false;

  dynamic _pendingCall;
  Timer? _pendingCallPoller;
  bool _respondingToCall = false;

  Timer? _heartbeatTimer;

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
  static const Color _infoBlue = Color(0xFF2196F3);
  static const Color _ratingGold = Color(0xFFFFB300);
  static const Color _goldAmber = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _pendingCallPoller = Timer.periodic(const Duration(seconds: 5), (_) => _pollForIncomingCall());
    _startHeartbeat();
  }

  @override
  void dispose() {
    _pendingCallPoller?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _sendHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    if (!_isOnline) return;
    final token = await SessionManager.getToken();
    if (token == null) return;
    try {
      await http.post(
        ApiConfig.uri(ApiEndpoints.influencerHeartbeat),
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _checkAuthentication() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    final user = await SessionManager.getUser();
    final email = user?['email']?.toString() ?? '';
    final statusResult = await _authenticationService.checkStatus(email);
    if (!mounted) return;
    if (statusResult is Map && statusResult['success'] == true) {
      final data = statusResult['data'];
      final authenticated = data is Map ? data['authenticated'] : null;
      if (authenticated == false) {
        await _authenticationService.sendOtp(email);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(email: email, token: token, role: 'influencer'),
            ),
          );
        }
        return;
      }
    }
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    try {
      final result = await _authService.checkProfileCompletion(token);
      if (!mounted) return;
      if (result['success'] == true && result['profile_completed'] == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfileScreen()),
        );
        return;
      }
    } catch (e) {}
    await _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    if (_profile != null) setState(() => _isRefreshing = true);

    try {
      final results = await Future.wait([
        _profileService.getProfile(token),
        _influencerService.getEarnings(token),
        _walletService.getHistory(token, limit: 5),
      ]).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final profResult = results[0];
      final earningsResult = results[1];
      final historyResult = results[2];

      if (profResult is Map && profResult['success'] == true) {
        final data = profResult['data'];
        if (data is Map) {
          setState(() {
            _profile = Map<String, dynamic>.from(data);
            _isOnline = _profile?['online_status'] == 'online';
            final profileBalance = _profile?['wallet_balance'];
            if (profileBalance != null) _walletBalance = _parseNumber(profileBalance);
          });
        }
      }

      if (earningsResult is Map && earningsResult['success'] == true) {
        final data = earningsResult['data'];
        if (data is Map) {
          setState(() {
            _earnings = Map<String, dynamic>.from(data);
            final earningsBalance = _earnings?['wallet_balance'];
            if (earningsBalance != null && _walletBalance == 0) {
              _walletBalance = _parseNumber(earningsBalance);
            }
          });
        }
      }

      if (historyResult is Map && historyResult['success'] == true) {
        final raw = historyResult['data'];
        final list = raw is Map ? (raw['history'] ?? raw['transactions'] ?? []) : raw;
        setState(() => _recentActivities = (list is List) ? list.take(5).toList() : []);
      }

      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      _fetchWalletBalance(token);
      _maybePromptWhatOffer(token);
    } catch (e) {
      if (mounted) setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _maybePromptWhatOffer(String token) async {
    if (_whatOfferPromptShown || !mounted) return;
    _whatOfferPromptShown = true;

    dynamic result;
    try {
      result = await _paygService.getWhatOffer(token);
    } catch (_) {
      _whatOfferPromptShown = false;
      return;
    }

    if (!mounted || result is! Map || result['success'] != true) {
      _whatOfferPromptShown = false;
      return;
    }

    final data = result['data'];
    final status = data is Map ? data['status'] : null;
    final offer = data is Map ? data['what_offer']?.toString().trim() : null;
    if (status == 1 || (offer != null && offer.isNotEmpty)) return;

    final controller = TextEditingController();
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool saving = false;
          String? error;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text(
                  'What will you be offering on the video call?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tell clients what they can expect from you during a video call.',
                      style: TextStyle(color: _textMedium, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Example: Friendly conversation, games, advice, entertainment...',
                        filled: true,
                        fillColor: _lightPink.withValues(alpha: 0.2),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _primaryPink, width: 1.5),
                        ),
                        errorText: error,
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            final value = controller.text.trim();
                            if (value.isEmpty) {
                              setDialogState(() => error = 'Please enter what you will offer.');
                              return;
                            }
                            setDialogState(() {
                              saving = true;
                              error = null;
                            });
                            final save = await _paygService.saveWhatOffer(token, value);
                            if (!mounted) return;
                            if (save is Map && save['success'] == true) {
                              Navigator.of(dialogContext).pop();
                              setState(() {
                                _profile = {
                                  ...?_profile,
                                  'what_offer': value,
                                  'what_offer_status': 1,
                                };
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('What I Offer saved successfully.'),
                                  backgroundColor: _successGreen,
                                ),
                              );
                            } else {
                              setDialogState(() {
                                saving = false;
                                error = save is Map
                                    ? (save['message']?.toString() ?? 'Failed to save. Please try again.')
                                    : 'Failed to save. Please try again.';
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(saving ? 'Saving...' : 'Submit'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _fetchWalletBalance(String token) async {
    try {
      final response = await http.get(
        ApiConfig.uri(ApiEndpoints.walletBalance),
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 8));
      final result = ApiConfig.handleResponse(response);
      if (result is Map && result['success'] == true) {
        final data = result['data'];
        if (data is Map) {
          final balance = data['available_balance'] ?? data['current_balance'] ?? data['balance'];
          if (balance != null) {
            final parsed = _parseNumber(balance);
            if (mounted && parsed != _walletBalance) setState(() => _walletBalance = parsed);
          }
        }
      }
    } catch (e) {}
  }

  num _parseNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  Future<void> _pollForIncomingCall() async {
    if (!mounted || !_isOnline || _respondingToCall) return;
    final token = await SessionManager.getToken();
    if (token == null) return;
    try {
      final result = await _callService.getPendingCall(token).timeout(const Duration(seconds: 5));
      if (!mounted) return;
      if (result is Map && result['success'] == true && result['data'] != null) {
        final newCall = result['data'];
        final newRequestId = newCall is Map ? newCall['request_id']?.toString() : null;
        final currentRequestId = _pendingCall is Map ? _pendingCall!['request_id']?.toString() : null;
        if (newRequestId != null && newRequestId != currentRequestId) {
          setState(() => _pendingCall = newCall);
          if (mounted) _showIncomingCallScreen();
        }
      } else if (result is Map && result['success'] == true && result['data'] == null) {
        if (_pendingCall != null) {
          setState(() => _pendingCall = null);
          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {}
  }

  void _showIncomingCallScreen() {
    final call = _pendingCall;
    if (call == null) return;
    final requestId = call['request_id']?.toString() ?? '';
    final callerName = call['client_mystery_name'] ?? 'A client';
    final callerImage = call['client_profile_photo'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _IncomingCallHost(
          call: call,
          isResponding: _respondingToCall,
          callerProfileImage: callerImage,
          onAccept: () => _acceptCall(requestId, callerName.toString()),
          onReject: () => _rejectCall(requestId),
          onTimeout: () => _handleCallTimeout(requestId),
        ),
      ),
    );
  }

  Future<void> _toggleOnline(bool value) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    setState(() => _isTogglingOnline = true);
    final result = await _influencerService.updateOnlineStatus(token, value ? 'online' : 'offline');
    if (mounted) {
      if (result is Map && result['success'] == true) {
        setState(() => _isOnline = value);
        if (value) {
          _sendHeartbeat();
          _heartbeatTimer?.cancel();
          _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
            _sendHeartbeat();
          });
        } else {
          _heartbeatTimer?.cancel();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result is Map ? result['message'] : null) ?? 'Failed to update status'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
      setState(() => _isTogglingOnline = false);
    }
  }

  Future<void> _acceptCall(String requestId, String clientName) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    setState(() => _respondingToCall = true);
    final result = await _callService.acceptCall(token, requestId);
    if (!mounted) return;
    setState(() {
      _respondingToCall = false;
      _pendingCall = null;
    });
    
    if (mounted) Navigator.pop(context);
    
    if (result is Map && result['success'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            callId: requestId,
            clientName: clientName,
          ),
        ),
      ).then((_) => _loadData());
    }
  }

  Future<void> _rejectCall(String requestId) async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }
    setState(() => _respondingToCall = true);
    await _callService.rejectCall(token, requestId);
    if (mounted) {
      setState(() {
        _respondingToCall = false;
        _pendingCall = null;
      });
      if (mounted) Navigator.pop(context);
    }
  }

  void _handleCallTimeout(String requestId) {
    if (!mounted) return;
    final currentRequestId =
        _pendingCall is Map ? _pendingCall!['request_id']?.toString() : null;

    setState(() {
      _pendingCall = null;
      _respondingToCall = false;
    });
    Navigator.pop(context);

    if (currentRequestId == requestId) {
      _autoRejectExpiredCall(requestId);
    }
  }

  Future<void> _autoRejectExpiredCall(String requestId) async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    try {
      await _callService.rejectCall(token, requestId);
    } catch (e) {
      // Best-effort cleanup only — nothing to show the user here.
    }
  }

  @override
  Widget build(BuildContext context) {
    final mysteryName = _profile?['mystery_name'] ?? 'Influencer';
    final todayEarnings = _earnings?['earnings']?['today'] ?? 0;
    final availableBalance = _walletBalance;
    final verificationStatus = _profile?['verification_status'];
    final isVerified = verificationStatus == 'verified' || verificationStatus == 'approved';
    final todayCalls = _earnings?['today_calls'] ?? 0;
    final totalCalls = _earnings?['total_calls'] ?? 0;
    final rating = _profile?['average_rating'] ?? '0.0';
    
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;

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
      body: SafeArea(
        child: Column(
          children: [
            _buildProfileHeader(mysteryName, isSmallScreen),
            Expanded(
              child: _isLoading && _profile == null
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
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          isSmallScreen ? 16 : 20,
                          horizontalPadding,
                          isSmallScreen ? 16 : 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isRefreshing)
                              Padding(
                                padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                                child: const Center(
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _primaryPink,
                                    ),
                                  ),
                                ),
                              ),

                            _buildProfileCard(mysteryName, rating, verificationStatus),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildBalanceCard(todayEarnings, availableBalance, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildQuickStats(todayCalls, totalCalls, rating, isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                            _buildStatusCard(isVerified, verificationStatus, isSmallScreen),
                            if (!isVerified)
                              Padding(
                                padding: EdgeInsets.only(top: isSmallScreen ? 6 : 8, left: 4),
                                child: Text(
                                  'Complete verification to go online and receive calls.',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    color: _textLight,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            SizedBox(height: isSmallScreen ? 20 : 24),
                            _buildRecentActivityHeader(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            _buildRecentActivityList(isSmallScreen),
                            SizedBox(height: isSmallScreen ? 16 : 20),
                          ],
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

  Widget _buildProfileHeader(String name, bool isSmallScreen) {
    final photoUrl = _profile?['profile_photo']?.toString();
    final country = _profile?['country_name']?.toString();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 20,
        isSmallScreen ? 8 : 12,
        isSmallScreen ? 8 : 12,
        isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _lightPink.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 2 : 2.5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryPink, _softPink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 22 : 26),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.18),
                  blurRadius: isSmallScreen ? 8 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 22),
                child: photoUrl != null && photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        width: isSmallScreen ? 36 : 44,
                        height: isSmallScreen ? 36 : 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildAvatarPlaceholder(name, isSmallScreen),
                      )
                    : _buildAvatarPlaceholder(name, isSmallScreen),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: _textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                if (country != null && country.isNotEmpty) ...[
                  SizedBox(height: isSmallScreen ? 1 : 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: isSmallScreen ? 10 : 12,
                        color: _primaryPink.withValues(alpha: 0.65),
                      ),
                      SizedBox(width: isSmallScreen ? 1 : 2),
                      Flexible(
                        child: Text(
                          country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 9 : 11,
                            color: _textMedium,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          _buildHeaderButton(Icons.notifications_outlined, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InfluencerNotificationsScreen(),
              ),
            ).then((_) => _loadData());
          }, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, VoidCallback onTap, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(right: isSmallScreen ? 4 : 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
          splashColor: _primaryPink.withValues(alpha: 0.05),
          highlightColor: _primaryPink.withValues(alpha: 0.03),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
              border: Border.all(
                color: _lightPink.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.08),
                  blurRadius: isSmallScreen ? 6 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: _textDark, size: isSmallScreen ? 18 : 22),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    String name,
    dynamic rating,
    dynamic verificationStatus,
  ) {
    // Profile photo, name, country, and notifications are now displayed
    // in the custom app bar above the dashboard.
    return const SizedBox.shrink();
  }

  Widget _buildAvatarPlaceholder(String name, bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 36 : 50,
      height: isSmallScreen ? 36 : 50,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPink, _softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(dynamic todayEarnings, dynamic availableBalance, bool isSmallScreen) {
    final todayValue = _parseNumber(todayEarnings);
    final balanceValue = _parseNumber(availableBalance);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 16 : 24,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryPink, _softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 18 : 24),
        boxShadow: [
          BoxShadow(
            color: _primaryPink.withValues(alpha: 0.3),
            blurRadius: isSmallScreen ? 12 : 20,
            offset: Offset(0, isSmallScreen ? 6 : 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                width: isSmallScreen ? 36 : 48,
                height: isSmallScreen ? 36 : 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _goldAmber,
                  size: isSmallScreen ? 20 : 26,
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$balanceValue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 30 : 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: isSmallScreen ? 4 : 6),
              Padding(
                padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 7),
                child: Text(
                  'Coins',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isSmallScreen ? 13 : 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 18),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          SizedBox(height: isSmallScreen ? 10 : 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Earnings",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 3),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+$todayValue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 24,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 2 : 4),
                      Padding(
                        padding: EdgeInsets.only(bottom: isSmallScreen ? 1 : 2),
                        child: Text(
                          'Coins',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 10 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: isSmallScreen ? 6 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WithdrawalScreen(),
                    ),
                  ).then((_) => _loadData()),
                  icon: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: isSmallScreen ? 14 : 16,
                    color: _primaryPink,
                  ),
                  label: Text(
                    'Withdraw',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isSmallScreen ? 11 : 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryPink,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(dynamic todayCalls, dynamic totalCalls, dynamic rating, bool isSmallScreen) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            Icons.phone_in_talk_rounded,
            'Today Calls',
            '${_parseNumber(todayCalls)}',
            _primaryPink,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildQuickStatCard(
            Icons.call_rounded,
            'Total Calls',
            '${_parseNumber(totalCalls)}',
            _infoBlue,
            isSmallScreen,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Expanded(
          child: _buildQuickStatCard(
            Icons.star_rounded,
            'Rating',
            rating.toString(),
            _ratingGold,
            isSmallScreen,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(IconData icon, String label, String value, Color color, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
        border: Border.all(
          color: _lightPink.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: isSmallScreen ? 6 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: isSmallScreen ? 2 : 3),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 8 : 10,
              color: _textMedium,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(bool isVerified, dynamic verificationStatus, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
        border: Border.all(
          color: _lightPink.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: isSmallScreen ? 6 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (isVerified ? _successGreen : Colors.orange).withValues(alpha: 0.12),
                        (isVerified ? _successGreen : Colors.orange).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    border: Border.all(
                      color: (isVerified ? _successGreen : Colors.orange).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isVerified
                        ? Icons.verified_rounded
                        : Icons.hourglass_top_rounded,
                    color: isVerified ? _successGreen : Colors.orange,
                    size: isSmallScreen ? 16 : 20,
                  ),
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified ? "I'm available for calls" : 'Pending Validation',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 14,
                          fontWeight: FontWeight.w600,
                          color: isVerified ? _successGreen : Colors.orange,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallScreen ? 1 : 2),
                      Text(
                        isVerified ? 'You can go online now' : 'Complete verification',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 11,
                          color: _textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryPink, _softPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                boxShadow: [
                  BoxShadow(
                    color: _primaryPink.withValues(alpha: 0.3),
                    blurRadius: isSmallScreen ? 6 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 18,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                  ),
                ),
                child: Text(
                  'Validate',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
              ),
            )
          else if (_isTogglingOnline)
            SizedBox(
              height: isSmallScreen ? 18 : 22,
              width: isSmallScreen ? 18 : 22,
              child: const CircularProgressIndicator(
                color: _primaryPink,
                strokeWidth: 2,
              ),
            )
          else
            Transform.scale(
              scale: isSmallScreen ? 0.8 : 0.9,
              child: Switch(
                value: _isOnline,
                activeColor: _primaryPink,
                onChanged: isVerified ? _toggleOnline : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityHeader(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryPink.withValues(alpha: 0.12),
                    _softPink.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
                border: Border.all(
                  color: _primaryPink.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                size: isSmallScreen ? 14 : 16,
                color: _primaryPink,
              ),
            ),
            SizedBox(width: isSmallScreen ? 6 : 10),
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 16,
                fontWeight: FontWeight.bold,
                color: _textDark,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: widget.onWalletTap,
          child: Text(
            'View All',
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: _primaryPink.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList(bool isSmallScreen) {
    if (_recentActivities.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
          border: Border.all(
            color: _lightPink.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
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
                color: _primaryPink.withValues(alpha: 0.5),
                size: isSmallScreen ? 24 : 32,
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 14),
            Text(
              'No recent activity',
              style: TextStyle(
                color: _textLight,
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 20),
        border: Border.all(
          color: _lightPink.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: isSmallScreen ? 6 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < _recentActivities.length; i++) ...[
            _buildActivityItem(_recentActivities[i], isSmallScreen),
            if (i != _recentActivities.length - 1)
              Divider(
                height: 1,
                indent: isSmallScreen ? 50 : 60,
                endIndent: isSmallScreen ? 12 : 16,
                color: _lightPink.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic item, bool isSmallScreen) {
    if (item is! Map) return const SizedBox.shrink();

    String description = item['description']?.toString() ?? '';
    String type = item['type']?.toString() ?? '';
    String reference = item['reference']?.toString() ?? '';

    if (description.isEmpty && type.isNotEmpty) {
      description = type;
    }

    if (type == 'escrow_release') {
      final nameMatch = RegExp(r'Payment from (\w+)', caseSensitive: false).firstMatch(reference);
      if (nameMatch != null) {
        description = 'Call with ${nameMatch.group(1)}';
      } else {
        description = 'Call payment received';
      }
    } else if (type == 'withdrawal_approved') {
      description = 'Withdrawal approved';
    } else if (type == 'withdrawal_rejected') {
      description = 'Withdrawal rejected';
    } else if (type == 'withdrawal_request') {
      description = 'Withdrawal requested';
    }

    description = description
        .replaceAll(RegExp(r'\(manual\)'), '')
        .replaceAll(RegExp(r'\(auto\)'), '')
        .replaceAll(RegExp(r'— Call #\d+'), '')
        .replaceAll(RegExp(r'— call #\d+'), '')
        .replaceAll(RegExp(r'\. Ref: [\w-]+'), '')
        .replaceAll(RegExp(r'\[manual\]'), '')
        .replaceAll(RegExp(r'\[auto\]'), '')
        .trim();

    final amount = _parseNumber(
      item['amount'] ?? item['coins'] ?? item['amount_change'] ?? item['coins_change'],
    );
    final isCredit = amount >= 0;
    final date = item['created_at']?.toString() ?? item['date']?.toString() ?? '';

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
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 14,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (isCredit ? _successGreen : _primaryPink).withValues(alpha: 0.12),
                  (isCredit ? _successGreen : _primaryPink).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
              border: Border.all(
                color: (isCredit ? _successGreen : _primaryPink).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? _successGreen : _primaryPink,
              size: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 2 : 3),
                Text(
                  displayDate,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 9 : 11,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isSmallScreen ? 4 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 8 : 10,
              vertical: isSmallScreen ? 4 : 5,
            ),
            decoration: BoxDecoration(
              color: (isCredit ? _successGreen : _primaryPink).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            ),
            child: Text(
              '${isCredit ? '+' : ''}${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 13,
                fontWeight: FontWeight.bold,
                color: isCredit ? _successGreen : _primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps IncomingCallScreen with a 40-second auto-timeout. If the influencer
/// doesn't accept or reject in time, it shows "Call Ended" on the incoming
/// screen briefly, then pops and notifies [onTimeout].
class _IncomingCallHost extends StatefulWidget {
  final Map<String, dynamic> call;
  final bool isResponding;
  final String? callerProfileImage;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTimeout;

  static const Duration timeoutDuration = Duration(seconds: 40);

  const _IncomingCallHost({
    required this.call,
    required this.isResponding,
    required this.onAccept,
    required this.onReject,
    required this.onTimeout,
    this.callerProfileImage,
  });

  @override
  State<_IncomingCallHost> createState() => _IncomingCallHostState();
}

class _IncomingCallHostState extends State<_IncomingCallHost> {
  Timer? _timeoutTimer;
  bool _resolved = false; // true once accepted, rejected, or timed out
  String? _statusOverride;

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(_IncomingCallHost.timeoutDuration, _handleTimeout);
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _handleTimeout() {
    if (_resolved || !mounted) return;
    _resolved = true;
    setState(() => _statusOverride = 'Call Ended');

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      widget.onTimeout();
    });
  }

  void _cancelTimeoutAnd(VoidCallback action) {
    if (_resolved) return;
    _resolved = true;
    _timeoutTimer?.cancel();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return IncomingCallScreen(
      call: widget.call,
      isResponding: widget.isResponding,
      callerProfileImage: widget.callerProfileImage,
      statusOverride: _statusOverride,
      onAccept: () => _cancelTimeoutAnd(widget.onAccept),
      onReject: () => _cancelTimeoutAnd(widget.onReject),
    );
  }
}