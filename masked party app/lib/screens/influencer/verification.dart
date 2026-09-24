// FILE LOCATION: lib/screens/influencer/verification.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maskedparty/screens/influencer/video_verification_camera.dart';
import 'package:maskedparty/services/influencer_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final InfluencerService _influencerService = InfluencerService();
  final ImagePicker _picker = ImagePicker();

  String? _governmentIdPath;
  String? _selfiePath;
  String? _verificationVideoPath;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

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

  // --- Progress budget ---
  static const double _kPreparingProgress = 0.05;
  static const double _kUploadWeight = 0.85;
  static const double _kMaxProgressBeforeConfirmed =
      _kPreparingProgress + _kUploadWeight; // 0.90

  // --- "Processing" trickle ---
  static const double _kProcessingCeiling = 0.95;
  static const Duration _kProcessingTrickleInterval = Duration(seconds: 2);
  static const double _kProcessingTrickleStep = 0.01;
  Timer? _processingTrickleTimer;

  void _startProcessingTrickle() {
    _processingTrickleTimer?.cancel();
    _processingTrickleTimer = Timer.periodic(_kProcessingTrickleInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final next = _uploadProgress + _kProcessingTrickleStep;
        if (next >= _kProcessingCeiling) {
          _uploadProgress = _kProcessingCeiling;
          timer.cancel();
        } else {
          _uploadProgress = next;
        }
      });
    });
  }

  void _stopProcessingTrickle() {
    _processingTrickleTimer?.cancel();
    _processingTrickleTimer = null;
  }

  @override
  void dispose() {
    _stopProcessingTrickle();
    super.dispose();
  }

  int get _totalDocuments => 3;

  int get _completedCount => [
        _governmentIdPath,
        _selfiePath,
        _verificationVideoPath,
      ].where((e) => e != null).length;

  bool get _allDocumentsReady =>
      _governmentIdPath != null &&
      _selfiePath != null &&
      _verificationVideoPath != null;

  Future<void> _pickGovernmentId() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file != null && mounted) setState(() => _governmentIdPath = file.path);
    } catch (e) {
      _showSnack('Could not select an image. Please try again.', isError: true);
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (file != null && mounted) setState(() => _selfiePath = file.path);
    } catch (e) {
      _showSnack('Could not open the camera. Please try again.', isError: true);
    }
  }

  Future<void> _recordVerificationVideo() async {
    try {
      final path = await Navigator.push<String?>(
        context,
        MaterialPageRoute(builder: (_) => const VideoVerificationCameraScreen()),
      );
      if (path != null && mounted) setState(() => _verificationVideoPath = path);
    } catch (e) {
      _showSnack('Could not open the camera. Please try again.', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_allDocumentsReady || _isLoading) return;

    final govIdFile = File(_governmentIdPath!);
    final selfieFile = File(_selfiePath!);
    final verificationVideoFile = File(_verificationVideoPath!);

    if (!await govIdFile.exists()) {
      _showSnack('Your government ID file is missing. Please re-upload it.', isError: true);
      setState(() => _governmentIdPath = null);
      return;
    }
    if (!await selfieFile.exists()) {
      _showSnack('Your selfie photo is missing. Please take it again.', isError: true);
      setState(() => _selfiePath = null);
      return;
    }
    if (!await verificationVideoFile.exists()) {
      _showSnack('Your verification video is missing. Please record it again.', isError: true);
      setState(() => _verificationVideoPath = null);
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _uploadStatus = '';
    });

    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    bool uploadSuccess = false;

    try {
      await _updateProgress(_kPreparingProgress, 'Preparing...');

      final result = await _influencerService.submitVerificationWithProgress(
        token,
        governmentIdPath: _governmentIdPath!,
        selfiePath: _selfiePath!,
        verificationVideoPath: _verificationVideoPath!,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;

          final uploadFraction = sent / total;
          final mapped = _kPreparingProgress + (uploadFraction * _kUploadWeight);

          setState(() {
            _uploadProgress = mapped.clamp(_kPreparingProgress, _kMaxProgressBeforeConfirmed);

            if (uploadFraction < 0.33) {
              _uploadStatus = 'Uploading government ID...';
            } else if (uploadFraction < 0.66) {
              _uploadStatus = 'Uploading selfie photo...';
            } else if (uploadFraction < 0.999) {
              _uploadStatus = 'Uploading verification video...';
            } else {
              _uploadStatus = 'Processing...';
              _startProcessingTrickle();
            }
          });
        },
      ).timeout(
        // FIX: kept in sync with kVerificationUploadTimeout (90s) in
        // influencer_service.dart. Was 5 minutes, which let a stuck upload
        // (server not responding) leave the user staring at a frozen
        // progress bar for far too long before ever surfacing an error.
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception(
            'The server is taking too long to respond. Please check your '
            'connection and try again.',
          );
        },
      );

      _stopProcessingTrickle();

      if (mounted) {
        final message = result is Map ? result['message'] : null;
        final success = result is Map && result['success'] == true;
        uploadSuccess = success;

        if (success) {
          await _updateProgress(1.0, 'Verification submitted!');
          
          _showSnack(
            message ?? 'Documents submitted for review!',
            isError: false,
          );

          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.of(context).maybePop();
        } else {
          _showSnack(
            message ?? 'Failed to submit',
            isError: true,
          );
          
          await _updateProgress(0.0, '');
        }
      }
    } catch (e) {
      if (mounted) {
        _stopProcessingTrickle();
        String errorMessage = 'Something went wrong. Please try again.';
        final str = e.toString();
        if (str.contains('timeout') || str.contains('Timeout')) {
          errorMessage = 'Upload timed out. Please check your connection.';
        } else if (str.contains('SocketException') || str.contains('Failed host lookup')) {
          errorMessage = 'No internet connection. Please check your network and try again.';
        } else if (str.contains('Exception: ')) {
          errorMessage = str.replaceFirst('Exception: ', '');
        }
        _showSnack(errorMessage, isError: true);
        await _updateProgress(0.0, '');
      }
    } finally {
      _stopProcessingTrickle();
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!uploadSuccess) {
            _uploadProgress = 0.0;
            _uploadStatus = '';
          }
        });
      }
    }
  }

  Future<void> _updateProgress(double progress, String status) async {
    if (!mounted) return;
    setState(() {
      _uploadProgress = progress;
      _uploadStatus = status;
    });
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
          'Verification',
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
          ? _buildUploadingState()
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner with enhanced design
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryPink.withValues(alpha: 0.08),
                          _softPink.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryPink.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
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
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: _primaryPink,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your profile becomes visible only after successful verification.',
                            style: TextStyle(
                              color: Color(0xFFC2185B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Upload progress card with enhanced design
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _lightPink.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryPink.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                                Icons.upload_rounded,
                                size: 16,
                                color: _primaryPink,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Upload Documents',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _textDark,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_completedCount of $_totalDocuments documents uploaded',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: _completedCount / _totalDocuments),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: _lightPink.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _completedCount == _totalDocuments
                                      ? _successGreen
                                      : _primaryPink,
                                ),
                                minHeight: 8,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Document cards with enhanced design
                  _buildDocumentCard(
                    title: 'Government ID',
                    subtitle: 'Upload a clear photo of your ID',
                    icon: Icons.badge_outlined,
                    isComplete: _governmentIdPath != null,
                    previewPath: _governmentIdPath,
                    onTap: _pickGovernmentId,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    title: 'Selfie Photo',
                    subtitle: 'Take a clear selfie of your face',
                    icon: Icons.face_retouching_natural_outlined,
                    isComplete: _selfiePath != null,
                    previewPath: _selfiePath,
                    onTap: _captureSelfie,
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentCard(
                    title: 'Verification Video',
                    subtitle: 'Record a $kVerificationVideoSeconds-second selfie video',
                    icon: Icons.videocam_outlined,
                    isComplete: _verificationVideoPath != null,
                    previewPath: _verificationVideoPath,
                    isVideo: true,
                    onTap: _recordVerificationVideo,
                  ),
                  const SizedBox(height: 20),
                  
                  // Privacy note with enhanced design
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _lightPink.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _primaryPink.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: _primaryPink.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your documents are private and reviewed only for verification purposes.',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textMedium,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Submit button with gradient
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: _allDocumentsReady
                          ? const LinearGradient(
                              colors: [_primaryPink, _softPink],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: _allDocumentsReady
                          ? null
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _allDocumentsReady
                          ? [
                              BoxShadow(
                                color: _primaryPink.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: ElevatedButton(
                      onPressed: _allDocumentsReady ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: _textLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Submit Verification',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    ),
      ),
    );
  }

  Widget _buildUploadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _lightPink.withValues(alpha: 0.4),
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
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: _uploadProgress),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOut,
            builder: (context, animatedProgress, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: animatedProgress > 0 ? animatedProgress : null,
                          strokeWidth: 4,
                          backgroundColor: _lightPink.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(_primaryPink),
                        ),
                      ),
                      if (animatedProgress > 0)
                        Text(
                          '${(animatedProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _primaryPink,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _uploadStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we upload your documents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _textMedium,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: animatedProgress > 0 ? animatedProgress : null,
                      backgroundColor: _lightPink.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(_successGreen),
                      minHeight: 8,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isComplete,
    required String? previewPath,
    required VoidCallback onTap,
    bool isVideo = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isComplete
              ? _successGreen.withValues(alpha: 0.3)
              : _lightPink.withValues(alpha: 0.4),
          width: isComplete ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: _primaryPink.withValues(alpha: 0.05),
          highlightColor: _primaryPink.withValues(alpha: 0.03),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Document preview/icon with gradient border
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: isComplete
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _successGreen.withValues(alpha: 0.12),
                              _successGreen.withValues(alpha: 0.05),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryPink.withValues(alpha: 0.12),
                              _softPink.withValues(alpha: 0.06),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isComplete
                          ? _successGreen.withValues(alpha: 0.2)
                          : _primaryPink.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: previewPath != null
                      ? (isVideo
                          ? const Icon(
                              Icons.videocam_rounded,
                              color: _successGreen,
                              size: 26,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(previewPath),
                                fit: BoxFit.cover,
                              ),
                            ))
                      : Icon(
                          icon,
                          color: isComplete ? _successGreen : _primaryPink,
                          size: 26,
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isComplete ? '✓ Ready' : subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isComplete ? _successGreen : _textMedium,
                          fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: isComplete
                        ? const LinearGradient(
                            colors: [_successGreen, Color(0xFF69F0AE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _primaryPink.withValues(alpha: 0.1),
                              _softPink.withValues(alpha: 0.05),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(10),
                    border: isComplete
                        ? null
                        : Border.all(
                            color: _primaryPink.withValues(alpha: 0.15),
                            width: 1,
                          ),
                  ),
                  child: Icon(
                    isComplete ? Icons.check_rounded : Icons.add_rounded,
                    color: isComplete ? Colors.white : _primaryPink,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}