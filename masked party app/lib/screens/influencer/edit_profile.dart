// FILE LOCATION: lib/screens/influencer/edit_profile.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maskedparty/services/profile_service.dart';
import 'package:maskedparty/services/upload_service.dart';
import 'package:maskedparty/services/session_manager.dart';
import 'gallery.dart';

class InfluencerEditProfileScreen extends StatefulWidget {
  const InfluencerEditProfileScreen({super.key});

  @override
  State<InfluencerEditProfileScreen> createState() => _InfluencerEditProfileScreenState();
}

class _InfluencerEditProfileScreenState extends State<InfluencerEditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final UploadService _uploadService = UploadService();
  final _formKey = GlobalKey<FormState>();

  final _mysteryNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageController = TextEditingController();
  final _complexionController = TextEditingController();
  final _foodController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _aspirationController = TextEditingController();
  final _targetController = TextEditingController();

  String _maskStatus = 'masked';
  bool _willingToRemoveMask = false;
  String? _existingPhotoUrl;
  String? _newPhotoPath;
  List<dynamic> _galleryPreview = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _mysteryNameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _complexionController.dispose();
    _foodController.dispose();
    _hobbyController.dispose();
    _aspirationController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }
    final result = await _profileService.getProfile(token);
    if (mounted && result is Map && result['success'] == true) {
      final data = result['data'] ?? {};
      setState(() {
        _mysteryNameController.text = data['mystery_name']?.toString() ?? '';
        _bioController.text = data['biography']?.toString() ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _complexionController.text = data['complexion']?.toString() ?? '';
        _foodController.text = data['favourite_food']?.toString() ?? '';
        _hobbyController.text = data['hobby']?.toString() ?? '';
        _aspirationController.text = data['aspiration']?.toString() ?? '';
        _targetController.text = data['financial_target']?.toString() ?? '';
        _maskStatus = data['mask_status']?.toString() ?? 'masked';
        _willingToRemoveMask = data['willing_to_remove_mask'] == true;
        _existingPhotoUrl = data['profile_photo']?.toString();
        _galleryPreview = (data['gallery'] is List) ? List.from(data['gallery']) : [];
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    setState(() => _isUploadingPhoto = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    // FIX: was calling uploadImage() (api/upload/image.php), which stores
    // files under uploads/chat/images/ — meant for chat attachments, not
    // avatars. uploadProfilePhoto() hits the dedicated profile endpoint
    // that stores under uploads/profiles/ and saves it to the DB directly.
    final uploadResult =
        await _uploadService.uploadProfilePhoto(token, file.path);
    if (!mounted) return;

    if (uploadResult is Map && uploadResult['success'] == true) {
      final url = uploadResult['data']?['url'] as String?;
      setState(() {
        _newPhotoPath = file.path;
        if (url != null) _existingPhotoUrl = url;
      });
    } else {
      final message = uploadResult is Map ? uploadResult['message'] : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Failed to upload photo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final token = await SessionManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      return;
    }

    final data = <String, dynamic>{
      'mystery_name': _mysteryNameController.text.trim(),
      'biography': _bioController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'complexion': _complexionController.text.trim(),
      'favourite_food': _foodController.text.trim(),
      'hobby': _hobbyController.text.trim(),
      'aspiration': _aspirationController.text.trim(),
      'financial_target': double.tryParse(_targetController.text.trim()) ?? 0,
      'mask_status': _maskStatus,
      'willing_to_remove_mask': _willingToRemoveMask,
    };

    if (_existingPhotoUrl != null) data['profile_photo'] = _existingPhotoUrl;

    final result = await _profileService.updateProfile(token, data);
    if (mounted) {
      if (result is Map && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop();
      } else {
        final message = result is Map ? result['message'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? 'Update failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() => _isSaving = false);
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
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1A1D2E), size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Color(0xFF1A1D2E), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Photo
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE91E63), Color(0xFFFF6B8B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(55),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(52),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(49),
                                  child: _newPhotoPath != null
                                      ? Image.file(File(_newPhotoPath!), height: 98, width: 98, fit: BoxFit.cover)
                                      : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty
                                          ? Image.network(_existingPhotoUrl!, height: 98, width: 98, fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildPhotoPlaceholder())
                                          : _buildPhotoPlaceholder()),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE91E63),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE91E63).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: _isUploadingPhoto
                                        ? const SizedBox(height: 16, width: 16,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text('Tap to change photo', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ),
                    const SizedBox(height: 24),

                    // Form Fields Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField('Mystery Name', Icons.masks_rounded, _mysteryNameController, 'Enter mystery name', validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                          const SizedBox(height: 16),
                          _buildField('Biography', Icons.description_outlined, _bioController, 'Tell clients about yourself...', maxLines: 3),
                          const SizedBox(height: 16),
                          _buildField('Age', Icons.cake_outlined, _ageController, 'Age', keyboardType: TextInputType.number),
                          const SizedBox(height: 16),
                          _buildField('Complexion', Icons.face_outlined, _complexionController, 'e.g. Fair, Olive, Dark'),
                          const SizedBox(height: 16),
                          _buildField('Favourite Food', Icons.restaurant_outlined, _foodController, 'e.g. Sushi'),
                          const SizedBox(height: 16),
                          _buildField('Hobby', Icons.palette_outlined, _hobbyController, 'e.g. Painting'),
                          const SizedBox(height: 16),
                          _buildField('Aspiration', Icons.emoji_objects_outlined, _aspirationController, 'What are you working towards?'),
                          const SizedBox(height: 16),
                          _buildField('Financial Target', Icons.attach_money_rounded, _targetController, '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true), prefixText: '\$ '),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mask Settings Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(Icons.masks_rounded, 'Mask Status'),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _maskStatus,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'masked', child: Text('🔒 Masked')),
                                DropdownMenuItem(value: 'unmasked', child: Text('🔓 Unmasked')),
                              ],
                              onChanged: (value) {
                                if (value != null) setState(() => _maskStatus = value);
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Willing to remove mask for the right motivation?',
                                style: TextStyle(fontSize: 13, color: Color(0xFF1A1D2E))),
                            value: _willingToRemoveMask,
                            activeTrackColor: const Color(0xFFE91E63).withOpacity(0.3),
                            activeColor: const Color(0xFFE91E63),
                            onChanged: (v) => setState(() => _willingToRemoveMask = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gallery Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel(Icons.photo_library_outlined, 'Gallery'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ..._galleryPreview.take(3).map((img) {
                                final url = img is Map ? img['url']?.toString() : img.toString();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      url ?? '',
                                      height: 70,
                                      width: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 70,
                                        width: 70,
                                        color: Colors.grey[100],
                                        child: const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GalleryScreen())),
                                child: Container(
                                  height: 70,
                                  width: 70,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.3), width: 1.5),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Color(0xFFE91E63), size: 28),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(height: 20, width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildPhotoPlaceholder() {
    return Container(
      height: 98,
      width: 98,
      color: const Color(0xFFE91E63).withOpacity(0.05),
      child: const Icon(Icons.person_rounded, size: 48, color: Colors.grey),
    );
  }

  Widget _buildFieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFFE91E63)),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1D2E))),
      ],
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(icon, label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.w600, fontSize: 14),
            filled: true,
            fillColor: const Color(0xFFF8F9FE),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE91E63), width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}