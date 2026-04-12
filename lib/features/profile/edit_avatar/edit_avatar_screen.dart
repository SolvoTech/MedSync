import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/user_error_message.dart';
import '../../../core/extensions/context_ext.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/app_dialog.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key});

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  static const int _maxAvatarBytes = 3 * 1024 * 1024;
  bool _isLoading = false;

  String _contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _fallbackDisplayName(User user) {
    final metadataName = (user.userMetadata?['full_name'] as String?)?.trim();
    if (metadataName != null && metadataName.isNotEmpty) {
      return metadataName;
    }

    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return localPart;
      }
    }

    return AppStrings.tr('User', 'Pengguna');
  }

  String _avatarUploadErrorMessage(Object error) {
    if (error is StorageException) {
      final lower = error.message.toLowerCase();
      if (lower.contains('bucket') && lower.contains('not found')) {
        return AppStrings.tr(
          'Avatar storage is not configured yet. Please contact admin.',
          'Penyimpanan avatar belum dikonfigurasi. Silakan hubungi admin.',
        );
      }
      if (lower.contains('permission') ||
          lower.contains('row-level security')) {
        return AppStrings.tr(
          'You do not have permission to upload avatar.',
          'Anda tidak memiliki izin untuk mengunggah avatar.',
        );
      }

      if (lower.contains('mime') ||
          lower.contains('content type') ||
          lower.contains('invalid') && lower.contains('image')) {
        return AppStrings.tr(
          'Image format is not supported. Please use JPG, PNG, or WEBP.',
          'Format gambar tidak didukung. Gunakan JPG, PNG, atau WEBP.',
        );
      }

      if (lower.contains('size') ||
          lower.contains('too large') ||
          lower.contains('payload') ||
          lower.contains('limit')) {
        final maxMb = (_maxAvatarBytes / (1024 * 1024)).round();
        return AppStrings.tr(
          'Profile photo is too large. Maximum $maxMb MB.',
          'Ukuran foto profil terlalu besar. Maksimal $maxMb MB.',
        );
      }
    }

    return toUserErrorMessage(
      error,
      fallback: AppStrings.tr(
        'Failed to update profile photo. Please try again.',
        'Gagal mengubah foto profil. Silakan coba lagi.',
      ),
    );
  }

  bool _isSupportedExtension(String extension) {
    return extension == 'jpg' || extension == 'png' || extension == 'webp';
  }

  Future<Uint8List> _compressToAvatarSafeBytes(Uint8List originalBytes) async {
    Uint8List bytes = originalBytes;
    var quality = 82;

    while (bytes.lengthInBytes > _maxAvatarBytes && quality >= 42) {
      final compressed = await FlutterImageCompress.compressWithList(
        bytes,
        quality: quality,
        minWidth: 1080,
        minHeight: 1080,
        format: CompressFormat.jpeg,
      );

      if (compressed.isEmpty) {
        break;
      }

      bytes = compressed;
      quality -= 10;
    }

    return bytes;
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

      croppedFile ??= CroppedFile(pickedFile.path);

      setState(() => _isLoading = true);

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final previousProfile = await client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      final previousAvatarUrl = previousProfile?['avatar_url'] as String?;

      final file = File(croppedFile.path);
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      var extension = file.path.toLowerCase().endsWith('.png')
          ? 'png'
          : file.path.toLowerCase().endsWith('.webp')
          ? 'webp'
          : 'jpg';
      var contentType = _contentTypeFor(file.path);
      var bytes = await file.readAsBytes();

      if (bytes.isEmpty) {
        throw Exception('Avatar image file is empty.');
      }

      if (!_isSupportedExtension(extension) ||
          bytes.lengthInBytes > _maxAvatarBytes) {
        final compressedBytes = await _compressToAvatarSafeBytes(bytes);
        if (compressedBytes.isNotEmpty) {
          bytes = compressedBytes;
          extension = 'jpg';
          contentType = 'image/jpeg';
        }
      }

      if (bytes.lengthInBytes > _maxAvatarBytes) {
        if (mounted) {
          final maxMb = (_maxAvatarBytes / (1024 * 1024)).round();
          context.showWarningSnackBar(
            AppStrings.tr(
              'Profile photo is too large. Maximum $maxMb MB.',
              'Ukuran foto profil terlalu besar. Maksimal $maxMb MB.',
            ),
          );
        }
        return;
      }

      final uploadPath = '${user.id}/avatar_$uniqueId.$extension';

      await client.storage
          .from('avatars')
          .uploadBinary(
            uploadPath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final publicUrl = client.storage.from('avatars').getPublicUrl(uploadPath);

      await client
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', user.id);

      final existingRows =
          await client.from('profiles').select('id').eq('id', user.id).limit(1)
              as List<dynamic>;

      if (existingRows.isEmpty) {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': _fallbackDisplayName(user),
          'avatar_url': publicUrl,
        });
      }

      await ImageCacheService.evictUrl(previousAvatarUrl);
      await ImageCacheService.evictUrl(publicUrl);

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
        context.showErrorSnackBar(_avatarUploadErrorMessage(e));
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

      final previousProfile = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      final previousAvatarUrl = previousProfile?['avatar_url'] as String?;

      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', user.id);

      await ImageCacheService.evictUrl(previousAvatarUrl);

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
