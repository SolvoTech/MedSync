import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/image_helper.dart';
import '../../data/remote/supabase_client.dart';

class TaskCompletionProof {
  const TaskCompletionProof({
    required this.photoPath,
    required this.capturedAt,
    required this.uploadedAt,
  });

  final String photoPath;
  final DateTime capturedAt;
  final DateTime uploadedAt;
}

enum _ProofPreviewAction { use, retake, cancel }

Future<TaskCompletionProof?> captureAndUploadTaskCompletionProof(
  BuildContext context, {
  required String taskType,
  required String referenceId,
}) async {
  while (context.mounted) {
    final capturedAt = DateTime.now();
    final file = await ImagePickerHelper.pickAndCompressImage(
      ImageSource.camera,
      quality: 72,
      minWidth: 1280,
      minHeight: 1280,
    );

    if (file == null || !context.mounted) {
      return null;
    }

    final action = await _showProofPreview(context, file);
    if (action == _ProofPreviewAction.cancel || !context.mounted) {
      return null;
    }
    if (action == _ProofPreviewAction.retake) {
      continue;
    }

    return _uploadProof(
      file: file,
      taskType: taskType,
      referenceId: referenceId,
      capturedAt: capturedAt,
    );
  }

  return null;
}

Future<TaskCompletionProof> _uploadProof({
  required File file,
  required String taskType,
  required String referenceId,
  required DateTime capturedAt,
}) async {
  final client = SupabaseClientRef.maybeClient;
  if (client == null) {
    throw const AppException('Supabase belum diinisialisasi.');
  }

  final user = client.auth.currentUser;
  if (user == null) {
    throw const AppException('Anda harus login terlebih dahulu.');
  }

  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    throw const AppException('File bukti foto kosong. Silakan ambil ulang.');
  }

  const maxBytes = 5 * 1024 * 1024;
  if (bytes.lengthInBytes > maxBytes) {
    throw const AppException('Ukuran bukti foto terlalu besar. Maksimal 5 MB.');
  }

  final extension = _detectImageExtension(file.path);
  final uploadedAt = DateTime.now();
  final path =
      '${user.id}/${_safePathPart(taskType)}/${_safePathPart(referenceId)}/proof_${uploadedAt.millisecondsSinceEpoch}.$extension';

  try {
    await client.storage
        .from('task-completion-proofs')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: _contentTypeForExtension(extension),
            upsert: true,
          ),
        );
  } on StorageException catch (error) {
    throw AppException(_storageErrorMessage(error));
  }

  return TaskCompletionProof(
    photoPath: path,
    capturedAt: capturedAt,
    uploadedAt: uploadedAt,
  );
}

Future<_ProofPreviewAction> _showProofPreview(
  BuildContext context,
  File file,
) async {
  final result = await showDialog<_ProofPreviewAction>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final media = MediaQuery.sizeOf(context);
      final compact = media.width < 360;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 20,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.height * 0.86),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.taskProofPreviewTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: AppStrings.cancel,
                      onPressed: () =>
                          Navigator.of(context).pop(_ProofPreviewAction.cancel),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: Image.file(
                      file,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.taskProofPreviewHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackButtons =
                        constraints.maxWidth < 340 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.08;
                    final retakeButton = OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_ProofPreviewAction.retake),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        AppStrings.taskProofRetakeAction,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    );
                    final useButton = FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pop(_ProofPreviewAction.use),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        AppStrings.taskProofUseAction,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    );

                    if (stackButtons) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          useButton,
                          const SizedBox(height: 10),
                          retakeButton,
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: retakeButton),
                        const SizedBox(width: 10),
                        Expanded(child: useButton),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  return result ?? _ProofPreviewAction.cancel;
}

String _detectImageExtension(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'png';
  }
  if (lower.endsWith('.webp')) {
    return 'webp';
  }
  return 'jpg';
}

String _contentTypeForExtension(String extension) {
  switch (extension) {
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    default:
      return 'image/jpeg';
  }
}

String _safePathPart(String value) {
  return value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

String _storageErrorMessage(StorageException error) {
  final lower = error.message.toLowerCase();

  if (lower.contains('bucket') && lower.contains('not found')) {
    return 'Penyimpanan bukti foto belum dikonfigurasi. Silakan hubungi admin.';
  }

  if (lower.contains('permission') || lower.contains('row-level security')) {
    return 'Anda tidak memiliki izin untuk mengunggah bukti foto.';
  }

  if (lower.contains('mime') ||
      lower.contains('content type') ||
      (lower.contains('invalid') && lower.contains('image'))) {
    return 'Format bukti foto tidak didukung. Gunakan JPG, PNG, atau WEBP.';
  }

  if (lower.contains('size') ||
      lower.contains('too large') ||
      lower.contains('payload') ||
      lower.contains('limit')) {
    return 'Ukuran bukti foto terlalu besar. Maksimal 5 MB.';
  }

  return 'Gagal mengunggah bukti foto. Silakan coba lagi.';
}
