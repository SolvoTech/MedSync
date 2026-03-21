import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/app_dialog.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key});

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  bool _isLoading = false;

  String _contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final toolbarColor = Theme.of(context).primaryColor;

    try {
      final pickedFile = await ImagePickerHelper.pickAndCompressImage(source);
      if (pickedFile == null) return;

      CroppedFile? croppedFile;
      try {
        croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: AppStrings.tr('Crop Avatar', 'Potong Avatar'),
              toolbarColor: toolbarColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: AppStrings.tr('Crop Avatar', 'Potong Avatar')),
          ],
        );
      } catch (_) {
        if (mounted) {
          context.showWarningSnackBar(
            AppStrings.tr(
              'Photo crop is not available on this device. Original photo will be used.',
              'Proses potong foto tidak tersedia di perangkat ini. Foto asli akan digunakan.',
            ),
          );
        }
      }

      if (croppedFile == null) {
        croppedFile = CroppedFile(pickedFile.path);
      }

      setState(() => _isLoading = true);

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final file = File(croppedFile.path);
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : file.path.toLowerCase().endsWith('.webp')
          ? 'webp'
          : 'jpg';
      final path = '${user.id}/avatar_$uniqueId.$extension';
      final contentType = _contentTypeFor(file.path);
      final bytes = await file.readAsBytes();

      await client.storage
          .from('avatars')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(path);

      await client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id)
          .select('id')
          .single();

      if (mounted) {
        Navigator.pop(context, true);
        context.showSuccessSnackBar(
          AppStrings.tr(
            'Profile photo updated successfully.',
            'Foto profil berhasil diubah.',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to update profile photo. Please try again.',
              'Gagal mengubah foto profil. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.tr('Delete Profile Photo?', 'Hapus Foto Profil?'),
      message: AppStrings.tr(
        'Your profile photo will be removed. You can add a new photo anytime.',
        'Foto profil akan dihapus dari profil Anda. Anda masih bisa menambahkan foto baru kapan saja.',
      ),
      confirmLabel: AppStrings.delete,
      isDestructive: true,
      icon: Icons.delete_outline,
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);

      if (mounted) {
        Navigator.pop(context, true);
        context.showSuccessSnackBar(
          AppStrings.tr('Profile photo deleted.', 'Foto profil dihapus.'),
        );
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          toUserErrorMessage(
            e,
            fallback: AppStrings.tr(
              'Failed to delete profile photo. Please try again.',
              'Gagal menghapus foto profil. Silakan coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('Edit Profile Photo', 'Ubah Foto Profil')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(
                AppStrings.tr('Take Photo (Camera)', 'Ambil Foto (Kamera)'),
              ),
              onTap: () => _pickAndUploadImage(ImageSource.camera),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(
                AppStrings.tr('Choose from Gallery', 'Pilih dari Galeri'),
              ),
              onTap: () => _pickAndUploadImage(ImageSource.gallery),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                AppStrings.tr('Delete Profile Photo', 'Hapus Foto Profil'),
                style: TextStyle(color: Colors.red),
              ),
              onTap: _removeAvatar,
            ),
          ),
        ],
      ),
    );
  }
}
