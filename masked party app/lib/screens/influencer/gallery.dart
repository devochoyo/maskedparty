// FILE LOCATION: lib/screens/influencer/gallery.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maskedparty/services/influencer_service.dart';
import 'package:maskedparty/services/session_manager.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const int _maxImages = 10;

  final InfluencerService _influencerService = InfluencerService();
  List<dynamic> galleryImages = [];
  bool _isLoading = true;
  bool _isUploading = false;

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
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final token = await SessionManager.getToken();
      if (token == null) {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }
        return;
      }
      
      final result = await _influencerService.getGallery(token).timeout(
        const Duration(seconds: 15),
      );
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (result is Map && result['success'] == true) {
          final data = result['data'];
          if (data is Map && data['gallery'] is List) {
            galleryImages = data['gallery'];
          } else if (data is List) {
            galleryImages = data;
          } else {
            galleryImages = [];
          }
        } else {
          galleryImages = [];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        galleryImages = [];
      });
    }
  }

  Future<void> _uploadImage() async {
    if (galleryImages.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You have reached the maximum of 10 gallery images'),
          backgroundColor: _warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted) return;
    if (file == null) {
      setState(() => _isUploading = false);
      return;
    }

    final token = await SessionManager.getToken();
    if (!mounted) return;
    if (token == null) {
      setState(() => _isUploading = false);
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      return;
    }

    final result = await _influencerService.uploadGallery(token, [file.path]);
    if (!mounted) return;
    setState(() => _isUploading = false);
    
    if (result is Map && result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Image uploaded successfully'),
          backgroundColor: _successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _loadGallery();
    } else {
      final data = result is Map ? result['data'] : null;
      final errors = data is Map ? data['upload_errors'] : null;
      final message = result is Map ? result['message'] : null;
      final errorText = (errors is List && errors.isNotEmpty) ? errors.first.toString() : message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorText ?? 'Upload failed'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      _loadGallery();
    }
  }

  Future<void> _deleteImage(String imageId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: _primaryPink, size: 28),
            SizedBox(width: 12),
            Text(
              'Delete Photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this photo?',
          style: TextStyle(
            fontSize: 15,
            color: _textMedium,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: _textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await SessionManager.getToken();
    if (token == null) return;
    
    final result = await _influencerService.deleteGalleryImage(token, imageId);
    if (mounted) {
      if (result is Map && result['success'] == true) {
        _loadGallery();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Photo deleted'),
            backgroundColor: _primaryPink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } else {
        final message = result is Map ? result['message'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Failed to delete image'),
            backgroundColor: Colors.red,
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
          'My Gallery',
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
          : Column(
              children: [
                // Counter Bar with enhanced design
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              Icons.photo_library_outlined,
                              color: _primaryPink,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${galleryImages.length} / $_maxImages photos',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryPink.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 12,
                              color: _textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Hold to delete',
                              style: TextStyle(
                                fontSize: 11,
                                color: _textMedium,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Gallery Grid with enhanced design
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadGallery,
                    color: _primaryPink,
                    backgroundColor: Colors.white,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: galleryImages.length + (galleryImages.length < _maxImages ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Add Photo Button with enhanced design
                        if (index == galleryImages.length) {
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: InkWell(
                              onTap: _isUploading ? null : _uploadImage,
                              borderRadius: BorderRadius.circular(18),
                              splashColor: _primaryPink.withValues(alpha: 0.05),
                              highlightColor: _primaryPink.withValues(alpha: 0.03),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _lightPink.withValues(alpha: 0.3),
                                      Colors.white,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: _primaryPink.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: _isUploading
                                    ? const Center(
                                        child: SizedBox(
                                          height: 28,
                                          width: 28,
                                          child: CircularProgressIndicator(
                                            color: _primaryPink,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  _primaryPink.withValues(alpha: 0.12),
                                                  _softPink.withValues(alpha: 0.06),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: _primaryPink.withValues(alpha: 0.15),
                                                width: 1,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.add_rounded,
                                              color: _primaryPink,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Add Photo',
                                            style: TextStyle(
                                              color: _primaryPink,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          );
                        }

                        // Gallery Image with enhanced design
                        final img = galleryImages[index];
                        final url = img is Map ? img['url']?.toString() : img.toString();
                        final id = img is Map ? img['id']?.toString() : null;

                        return GestureDetector(
                          onTap: () {
                            // View image full screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.black,
                                    elevation: 0,
                                    iconTheme: const IconThemeData(color: Colors.white),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: Image.network(url ?? '', fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          onLongPress: id == null
                              ? null
                              : () => _deleteImage(id),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: _lightPink.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                url ?? '',
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _primaryPink,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: _lightPink.withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: _primaryPink.withValues(alpha: 0.4),
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    ),
      ),
    );
  }
}