// FILE LOCATION: lib/screens/influencer/video_verification_camera.dart
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';

const int kVerificationVideoMilliseconds = 2500;

const double kVerificationVideoSeconds =
    kVerificationVideoMilliseconds / 1000; // 2.5

class VideoVerificationCameraScreen extends StatefulWidget {
  const VideoVerificationCameraScreen({super.key});

  @override
  State<VideoVerificationCameraScreen> createState() =>
      _VideoVerificationCameraScreenState();
}

class _VideoVerificationCameraScreenState
    extends State<VideoVerificationCameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  bool _isRecording = false;
  bool _isStopping = false;
  int _remainingMs = kVerificationVideoMilliseconds;
  Timer? _countdownTimer;
  String? _errorMessage;

  bool _isCompressing = false;
  double _compressionProgress = 0;
  Subscription? _compressionProgressSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _compressionProgressSub?.unsubscribe();
    if (_isCompressing) {
      VideoCompress.cancelCompression();
    }
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _countdownTimer?.cancel();
      controller.dispose();
      _controller = null;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null && !_isCompressing) {
      setState(() {
        _initializeControllerFuture = _initializeCamera();
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'No camera was found on this device.');
        return;
      }

      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _controller = controller;
      await controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      setState(() {
        _errorMessage = _friendlyCameraError(e);
      });
    }
  }

  String _friendlyCameraError(Object e) {
    final msg = e.toString();
    if (msg.contains('CameraAccessDenied') || msg.contains('permission')) {
      return 'Camera and microphone permission is required to record your verification video. Please enable it in your device settings.';
    }
    if (msg.contains('channel-error') || msg.contains('PigeonInternalInstanceManager')) {
      return 'Camera failed to initialize. If you are testing with hot restart, please fully stop and re-run the app — the camera plugin does not support hot restart on Android.';
    }
    return 'Could not start the camera. Please try again.';
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isRecording) {
      return;
    }

    try {
      await controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _remainingMs = kVerificationVideoMilliseconds;
      });

      const tick = Duration(milliseconds: 100);
      _countdownTimer = Timer.periodic(tick, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _remainingMs -= tick.inMilliseconds);
        if (_remainingMs <= 0) {
          timer.cancel();
          _stopRecording();
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Could not start recording. Please try again.');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording || _isStopping) return;

    setState(() => _isStopping = true);
    _countdownTimer?.cancel();

    try {
      final XFile file = await controller.stopVideoRecording();
      final finalPath = await _compressRecordedVideo(file.path);
      if (mounted) {
        Navigator.of(context).pop(finalPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isStopping = false;
          _errorMessage = 'Could not save the recording. Please try again.';
        });
      }
    }
  }

  Future<String> _compressRecordedVideo(String rawPath) async {
    if (mounted) {
      setState(() {
        _isCompressing = true;
        _compressionProgress = 0;
      });
    }

    _compressionProgressSub = VideoCompress.compressProgress$.subscribe((progress) {
      if (mounted) {
        setState(() => _compressionProgress = progress.clamp(0, 100));
      }
    });

    try {
      final info = await VideoCompress.compressVideo(
        rawPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      ).timeout(const Duration(seconds: 25), onTimeout: () => null);

      final compressedPath = info?.path;
      if (compressedPath == null || compressedPath.isEmpty) {
        return await _ensureMp4Name(rawPath);
      }

      final compressed = File(compressedPath);
      if (!await compressed.exists() || await compressed.length() == 0) {
        return await _ensureMp4Name(rawPath);
      }

      try {
        final raw = File(rawPath);
        if (raw.path != compressed.path && await raw.exists()) {
          await raw.delete();
        }
      } catch (_) {}

      return await _ensureMp4Name(compressed.path);
    } catch (e) {
      return await _ensureMp4Name(rawPath);
    } finally {
      _compressionProgressSub?.unsubscribe();
      _compressionProgressSub = null;
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  Future<String> _ensureMp4Name(String path) async {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.3gp')) {
      return path;
    }
    try {
      final src = File(path);
      if (!await src.exists()) return path;
      final destPath = '$path.mp4';
      final dest = File(destPath);
      if (!await dest.exists()) {
        await src.copy(destPath);
      }
      return destPath;
    } catch (_) {
      return path;
    }
  }

  void _cancel() {
    _countdownTimer?.cancel();
    Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing for compact Android widths, matching the existing screen pattern.
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    if (_isCompressing) {
      return _buildCompressingView();
    }

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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildCameraBody(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Material(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: _isRecording ? null : _cancel,
                borderRadius: BorderRadius.circular(30),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          if (_controller != null && _controller!.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: isSmallScreen ? 30 : 50,
              child: _buildBottomControls(isSmallScreen),
            ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildCompressingView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: _compressionProgress > 0 ? _compressionProgress / 100 : null,
                  strokeWidth: 4,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _compressionProgress > 0
                    ? 'Optimizing video... ${_compressionProgress.toInt()}%'
                    : 'Optimizing video...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This only takes a moment',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraBody() {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _initializeControllerFuture = _initializeCamera();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        final controller = _controller;
        if (snapshot.connectionState != ConnectionState.done ||
            controller == null ||
            !controller.value.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFE91E63)),
          );
        }

        return _buildCameraPreview(controller);
      },
    );
  }

  Widget _buildCameraPreview(CameraController controller) {
    return Center(
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(3.14159),
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildBottomControls(bool isSmallScreen) {
    final buttonSize = isSmallScreen ? 60.0 : 72.0;
    final iconSize = isSmallScreen ? 28.0 : 36.0;
    final fontSize = isSmallScreen ? 11.0 : 13.0;

    if (_isRecording) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: buttonSize + 10,
            height: buttonSize + 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: Center(
              child: Text(
                (_remainingMs.clamp(0, kVerificationVideoMilliseconds) / 1000)
                    .toStringAsFixed(1),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmallScreen ? 22 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.red, size: isSmallScreen ? 10 : 12),
                SizedBox(width: isSmallScreen ? 6 : 8),
                Text(
                  'Recording... hold still',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE91E63),
            ),
            child: Icon(
              Icons.fiber_manual_record_rounded,
              color: Colors.white,
              size: iconSize,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 8 : 12),
        Text(
          'Tap to record a $kVerificationVideoSeconds-second video',
          style: TextStyle(
            color: Colors.white70,
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}