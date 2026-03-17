import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/image_helper.dart';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key});

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen> {
  bool _isLoading = false;

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final toolbarColor = Theme.of(context).primaryColor;

    try {
      final pickedFile = await ImagePickerHelper.pickAndCompressImage(source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Potong Avatar',
            toolbarColor: toolbarColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Potong Avatar'),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final file = File(croppedFile.path);
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final path = '${user.id}/avatar_$uniqueId.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(path, file);

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(path);

      await Supabase.instance.client.from('profiles').update({
        'avatar_url': publicUrl,
      }).eq('id', user.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diubah.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah foto profil: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await Supabase.instance.client.from('profiles').update({
        'avatar_url': null,
      }).eq('id', user.id);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Foto Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto (Kamera)'),
              onTap: () => _pickAndUploadImage(ImageSource.camera),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () => _pickAndUploadImage(ImageSource.gallery),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Hapus Foto Profil',
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
