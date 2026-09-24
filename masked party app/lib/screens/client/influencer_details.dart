import 'dart:async';
import 'package:flutter/material.dart';
import 'package:maskedparty/services/client_service.dart';
import 'package:maskedparty/services/call_service.dart';
import 'package:maskedparty/services/report_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'package:maskedparty/services/influencer_active_status_service.dart';
import 'package:maskedparty/services/payg_service.dart';
import 'package:maskedparty/widgets/call_warning_dialog.dart';
import 'video_call.dart';
import '../shared/chat_detail.dart';

class InfluencerDetailsScreen extends StatefulWidget {
  final String influencerId;

  const InfluencerDetailsScreen({super.key, required this.influencerId});

  @override
  State<InfluencerDetailsScreen> createState() => _InfluencerDetailsScreenState();
}

class _InfluencerDetailsScreenState extends State<InfluencerDetailsScreen> {
  final ClientService _clientService = ClientService();
  final CallService _callService = CallService();
  final ReportService _reportService = ReportService();
  final InfluencerActiveStatusService _statusService = InfluencerActiveStatusService();
  final PaygService _paygService = PaygService();

  dynamic _influencer;
  bool _isLoading = true;
  bool _isSaved = false;
  bool _isRequestingCall = false;
  int _selectedMinutes = 5;

  Map<String, dynamic>? _activeStatus;
  Timer? _statusTimer;

  List<CallMinuteCostTier> _minuteCostTiers = [];
  PaygPricing? _paygPricing;

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
  static const Color _ratingGold = Color(0xFFFFC107);

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _loadMinuteCostTiers();
    _loadPaygPricing();
    _loadActiveStatus();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final result = await _clientService.getInfluencerDetails(token, widget.influencerId);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result is Map && result['success'] == true) {
        _influencer = result['data'];
        _isSaved = _influencer is Map && _influencer['is_saved'] == true;
      } else {
        _influencer = null;
      }
    });
  }

  Future<void> _loadActiveStatus() async {
    final token = await SessionManager.getToken();
    if (token == null) return;

    final status = await _statusService.getStatus(token, widget.influencerId);
    if (!mounted) return;

    setState(() {
      _activeStatus = status;
    });
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadActiveStatus();
    });
  }

  Future<void> _loadMinuteCostTiers() async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    final result = await _callService.getCallMinuteCosts(token);
    if (!mounted || result == null) return;
    setState(() {
      _minuteCostTiers = result.tiers;
      if (_minuteCostTiers.isNotEmpty) {
        _selectedMinutes = _minuteCostTiers.first.minutes;
      }
    });
  }

  Future<void> _loadPaygPricing() async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    final pricing = await _paygService.getPricing(token);
    if (!mounted || pricing == null) return;
    setState(() => _paygPricing = pricing);
  }

  Future<void> _requestPaygCall(String billingMode) async {
    if (_isRequestingCall) return;
    if (!_isTrulyOnline) return;

    final pricing = _paygPricing;
    if (pricing == null ||
        (billingMode == 'payg_minute' && pricing.perMinute <= 0) ||
        (billingMode == 'payg_second' && pricing.perSecond <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pay As You Go pricing is currently unavailable.')),
      );
      return;
    }

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CallWarningDialog(),
    );
    if (agreed != true || !mounted) return;

    setState(() => _isRequestingCall = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final result = await _callService.requestCall(
      token,
      widget.influencerId,
      billingMode: billingMode,
    );
    if (!mounted) return;
    setState(() => _isRequestingCall = false);

    if (result is Map && result['success'] == true) {
      final data = result['data'];
      final requestId = data is Map
          ? data['request_id']?.toString() ?? data['id']?.toString()
          : null;
      if (requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call server did not return a request id')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            requestId: requestId,
            influencerId: widget.influencerId,
            influencerName: _influencer is Map
                ? (_influencer['mystery_name']?.toString() ?? '')
                : '',
            initialMinutes: 1,
            billingMode: billingMode,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result is Map ? (result['message']?.toString() ?? 'Failed to request call') : 'Failed to request call',
          ),
        ),
      );
    }
  }

  Future<void> _showPaygOptions() async {
    if (!_isTrulyOnline || _isRequestingCall) return;
    final pricing = _paygPricing;
    if (pricing == null) {
      await _loadPaygPricing();
    }
    if (!mounted || _paygPricing == null) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final p = _paygPricing!;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryPink, _softPink],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 25),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pay As You Go',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: _textDark),
                ),
                const SizedBox(height: 5),
                Text(
                  'Choose how you want your video call to be billed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: _textMedium),
                ),
                const SizedBox(height: 18),
                _buildPaygChoice(
                  context,
                  icon: Icons.timer_rounded,
                  title: 'Pay per minute',
                  subtitle: 'Charged for each minute used',
                  price: '${_formatCoins(p.perMinute)} coins / minute',
                  value: 'payg_minute',
                ),
                const SizedBox(height: 10),
                _buildPaygChoice(
                  context,
                  icon: Icons.speed_rounded,
                  title: 'Pay per second',
                  subtitle: 'Charged precisely for seconds used',
                  price: '${_formatCoins(p.perSecond)} coins / second',
                  value: 'payg_second',
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) {
      await _requestPaygCall(selected);
    }
  }

  Widget _buildPaygChoice(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required String value,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _lightPink.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _lightPink.withValues(alpha: 0.8)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _primaryPink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _textDark, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: _textMedium, fontSize: 11.5)),
                  const SizedBox(height: 7),
                  Text(price, style: const TextStyle(color: _primaryPink, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _primaryPink),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleSave() async {
    final token = await SessionManager.getToken();
    if (token == null) return;
    setState(() => _isSaved = !_isSaved);
    final result = _isSaved
        ? await _clientService.saveInfluencer(token, widget.influencerId)
        : await _clientService.removeSavedInfluencer(token, widget.influencerId);
    if (!mounted) return;
    if (result is! Map || result['success'] != true) {
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update saved influencers')),
      );
    }
  }

  Future<void> _requestCall() async {
    if (_isRequestingCall) return;

    if (!_isTrulyOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This influencer is currently offline. Please try again later.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final agreed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CallWarningDialog(),
    );

    if (agreed != true || !mounted) return;

    setState(() => _isRequestingCall = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final result = await _callService.requestCall(token, widget.influencerId);
    if (!mounted) return;
    setState(() => _isRequestingCall = false);
    if (result is Map && result['success'] == true) {
      final data = result['data'];
      final requestId = data is Map ? data['request_id']?.toString() ?? data['id']?.toString() : null;
      if (requestId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call server did not return a request id')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            requestId: requestId,
            influencerId: widget.influencerId,
            influencerName: _influencer is Map
                ? (_influencer['mystery_name']?.toString() ?? '')
                : '',
            initialMinutes: _selectedMinutes,
          ),
        ),
      );
    } else {
      final message = result is Map ? result['message'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Failed to request call')),
      );
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          conversationId: widget.influencerId,
          otherUserId: widget.influencerId,
          otherUserName: _influencer is Map ? (_influencer['mystery_name']?.toString() ?? 'User') : 'User',
        ),
      ),
    );
  }

  Future<void> _reportUser() async {
    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();
    final reason = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          'Report User',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Reason (e.g. inappropriate behavior)',
                filled: true,
                fillColor: _lightPink.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryPink, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                filled: true,
                fillColor: _lightPink.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primaryPink, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'reason': reasonController.text.trim(),
              'description': descriptionController.text.trim(),
            }),
            child: const Text('Submit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (reason == null || reason['reason']!.isEmpty) return;
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final result = await _reportService.submitReport(
      token,
      widget.influencerId,
      '',
      reason['reason']!,
      reason['description'] ?? '',
    );
    if (mounted) {
      final success = result is Map && result['success'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Report submitted'
                : ((result is Map ? result['message'] : null) ?? 'Failed to submit report'),
          ),
        ),
      );
    }
  }

  double _toDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic value, [int fallback = 0]) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  double _costForMinutes(int mins, double pricePerMinute) {
    for (final tier in _minuteCostTiers) {
      if (tier.minutes == mins) return tier.coinCost;
    }
    return pricePerMinute * mins;
  }

  bool get _isTrulyOnline => _activeStatus?['is_truly_online'] == true;
  String get _statusDisplayText => _isTrulyOnline ? 'Online' : 'Offline';
  Color get _statusColor => _isTrulyOnline ? _successGreen : _textLight;

  bool get _isWearingMask {
    if (_influencer is! Map) return true;
    final status = _influencer['mask_status']?.toString().toLowerCase();
    return status != 'unmasked';
  }

  String get _maskStatusLabel =>
      _isWearingMask ? "Does Wear a Vail" : "Doesn't Wear a Vail";

  String _formatCoins(double amount) {
    if (amount % 1 == 0) return amount.toInt().toString();
    return amount.toStringAsFixed(1);
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _primaryPink)),
      );
    }

    if (_influencer == null) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: Text('Influencer not found')),
      );
    }

    final inf = _influencer as Map;
    final name = inf['mystery_name']?.toString() ?? '';
    final country = inf['country_name']?.toString() ?? '';
    final age = inf['age']?.toString();
    final biography = inf['biography']?.toString();
    final whatOffer = inf['what_offer']?.toString().trim();
    final rating = _toDouble(inf['average_rating']);
    final reviewCount = _toInt(inf['review_count'] ?? inf['total_calls']);
    final pricePerMinute = _toDouble(inf['price_per_minute']);
    final mainPhoto = inf['profile_photo']?.toString();
    final galleryRaw = inf['gallery'];
    final List gallery = galleryRaw is List ? galleryRaw : [];
    final List<int> durationOptions = _minuteCostTiers.isNotEmpty
        ? _minuteCostTiers.map((t) => t.minutes).toList()
        : const [5, 10, 15, 20];

    final double heroHeight = (screenHeight * 0.38 > 280 ? 280 : screenHeight * 0.38).toDouble();

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
          body: Column(
            children: [
              // Hero Image Section
              Stack(
                children: [
                  // Tappable hero image
                  GestureDetector(
                    onTap: mainPhoto != null && mainPhoto.isNotEmpty
                        ? () => _showFullImage(mainPhoto)
                        : null,
                    child: Container(
                      height: heroHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        child: (mainPhoto != null && mainPhoto.isNotEmpty)
                            ? Image.network(
                                mainPhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildPlaceholder(),
                              )
                            : _buildPlaceholder(),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Top Navigation
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 12,
                          vertical: isSmallScreen ? 4 : 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color: _textDark,
                                  size: isSmallScreen ? 18 : 20,
                                ),
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: _primaryPink,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    onPressed: _toggleSave,
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_horiz,
                                      color: _textDark,
                                      size: isSmallScreen ? 18 : 20,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'report') _reportUser();
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'report', child: Text('Report User')),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Name & Status
                  Positioned(
                    bottom: isSmallScreen ? 12 : 16,
                    left: isSmallScreen ? 12 : 20,
                    right: isSmallScreen ? 12 : 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 20 : 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 3 : 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: isSmallScreen ? 4 : 6,
                                    height: isSmallScreen ? 4 : 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 3 : 4),
                                  Text(
                                    _statusDisplayText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 9 : 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (country.isNotEmpty) ...[
                          SizedBox(height: isSmallScreen ? 2 : 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 12 : 14,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                country,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 11 : 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.star_rounded,
                              value: rating.toStringAsFixed(1),
                              label: 'Rating',
                              color: _ratingGold,
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.people_rounded,
                              value: reviewCount.toString(),
                              label: 'Reviews',
                              color: const Color(0xFF2196F3),
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.timer_rounded,
                              value: _formatCoins(pricePerMinute),
                              label: 'Coins/min',
                              color: _primaryPink,
                              isSmallScreen: isSmallScreen,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Mask Status
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 12 : 16,
                          vertical: isSmallScreen ? 10 : 12,
                        ),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                          border: Border.all(
                            color: _lightPink.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
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
                              ),
                              child: Icon(
                                Icons.masks_rounded,
                                size: isSmallScreen ? 18 : 22,
                                color: _primaryPink,
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 8 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _maskStatusLabel,
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 15,
                                      fontWeight: FontWeight.bold,
                                      color: _textDark,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 1 : 2),
                                  Text(
                                    _isWearingMask
                                        ? 'This influencer uses a face covering during calls'
                                        : 'This influencer does not wear a face covering',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 11 : 12,
                                      color: _textMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Gallery
                      if (gallery.isNotEmpty) ...[
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        SizedBox(
                          height: isSmallScreen ? 80 : 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: gallery.length,
                            separatorBuilder: (_, __) => SizedBox(width: isSmallScreen ? 8 : 10),
                            itemBuilder: (context, index) {
                              final item = gallery[index];
                              final String url = (item is Map)
                                  ? (item['url']?.toString() ?? '')
                                  : (item?.toString() ?? '');
                              return GestureDetector(
                                onTap: url.isNotEmpty ? () => _showFullImage(url) : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryPink.withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                                    child: url.isNotEmpty
                                        ? Image.network(
                                            url,
                                            width: isSmallScreen ? 80 : 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              width: isSmallScreen ? 80 : 100,
                                              color: _lightPink,
                                              child: const Icon(Icons.broken_image, color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            width: isSmallScreen ? 80 : 100,
                                            color: _lightPink,
                                            child: const Icon(Icons.broken_image, color: Colors.grey),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 18 : 24),
                      ],

                      // About
                      Text(
                        'About Me',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                          border: Border.all(
                            color: _lightPink.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          (biography == null || biography.isEmpty)
                              ? 'No biography available yet.'
                              : biography,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: _textMedium,
                            height: 1.6,
                          ),
                        ),
                      ),

                      // What I will offer on the video call
                      if (whatOffer != null && whatOffer.isNotEmpty) ...[
                        SizedBox(height: isSmallScreen ? 18 : 24),
                        Text(
                          'What I will offer on the video call',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: _textDark,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            color: _cardColor,
                            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                            border: Border.all(
                              color: _lightPink.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            whatOffer,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: _textMedium,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: screenHeight * 0.15),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Call Section
          bottomSheet: Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: _primaryPink.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Duration Selector
                Row(
                  children: [
                    for (final mins in durationOptions)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: mins == durationOptions.first ? 0 : 3,
                            right: mins == durationOptions.last ? 0 : 3,
                          ),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedMinutes = mins),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 8 : 12,
                              ),
                              decoration: BoxDecoration(
                                gradient: _selectedMinutes == mins
                                    ? const LinearGradient(
                                        colors: [_primaryPink, _softPink],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: _selectedMinutes == mins ? null : _lightPink.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 14),
                                border: Border.all(
                                  color: _selectedMinutes == mins
                                      ? _primaryPink
                                      : _lightPink.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$mins',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedMinutes == mins
                                          ? Colors.white
                                          : _textDark,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 1 : 2),
                                  Text(
                                    'mins',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 9 : 11,
                                      color: _selectedMinutes == mins
                                          ? Colors.white
                                          : _textMedium,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 3 : 4),
                                  Text(
                                    _formatCoins(_costForMinutes(mins, pricePerMinute)),
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 10 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedMinutes == mins
                                          ? Colors.white
                                          : _primaryPink,
                                    ),
                                  ),
                                  Text(
                                    'coins',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 8 : 10,
                                      color: _selectedMinutes == mins
                                          ? Colors.white
                                          : _textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 10 : 12),

                // Pay As You Go Button — only visible when influencer is online
                if (_isTrulyOnline) ...[
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 44 : 52,
                    child: OutlinedButton.icon(
                      onPressed: _isRequestingCall ? null : _showPaygOptions,
                      icon: Icon(
                        Icons.bolt_rounded,
                        size: isSmallScreen ? 18 : 21,
                      ),
                      label: Text(
                        'Pay As You Go',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryPink,
                        side: const BorderSide(
                          color: _primaryPink,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 8),
                ],

                // Normal Call Button
                Container(
                  width: double.infinity,
                  height: isSmallScreen ? 44 : 52,
                  decoration: BoxDecoration(
                    gradient: (_isTrulyOnline && !_isRequestingCall)
                        ? const LinearGradient(
                            colors: [_primaryPink, _softPink],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: (_isTrulyOnline && !_isRequestingCall)
                        ? null
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: (_isTrulyOnline && !_isRequestingCall)
                        ? [
                            BoxShadow(
                              color: _primaryPink.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _isTrulyOnline && !_isRequestingCall ? _requestCall : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isRequestingCall
                        ? SizedBox(
                            height: isSmallScreen ? 18 : 20,
                            width: isSmallScreen ? 18 : 20,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: isSmallScreen ? 16 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 4 : 8),
                              Text(
                                _isTrulyOnline ? 'Start Video Call' : 'Influencer Offline',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 40 : 48,
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    icon: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: isSmallScreen ? 16 : 18,
                    ),
                    label: Text(
                      'Send Message',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryPink,
                      side: const BorderSide(color: _primaryPink, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryPink.withValues(alpha: 0.2),
            _softPink.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 60,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: isSmallScreen ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
        border: Border.all(
          color: _lightPink.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.12),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 10),
            ),
            child: Icon(icon, color: color, size: isSmallScreen ? 16 : 20),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 15 : 18,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
          SizedBox(height: isSmallScreen ? 1 : 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 9 : 11,
              color: _textMedium,
            ),
          ),
        ],
      ),
    );
  }
}