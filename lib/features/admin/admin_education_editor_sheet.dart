part of 'admin_education_screen.dart';

class _ArticleEditorResult {
  const _ArticleEditorResult({
    required this.title,
    required this.slugInput,
    required this.summary,
    required this.content,
    required this.category,
    required this.coverUrl,
  });

  final String title;
  final String slugInput;
  final String summary;
  final String content;
  final String category;
  final String? coverUrl;
}

class _ArticleEditorSheet extends ConsumerStatefulWidget {
  const _ArticleEditorSheet({this.article});

  final EducationArticle? article;

  @override
  ConsumerState<_ArticleEditorSheet> createState() =>
      _ArticleEditorSheetState();
}

class _ArticleEditorSheetState extends ConsumerState<_ArticleEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  static const int _maxCoverBytes = 5 * 1024 * 1024;

  late final TextEditingController _titleController;
  late final TextEditingController _slugController;
  late final TextEditingController _categoryController;
  late final TextEditingController _summaryController;
  late final TextEditingController _contentController;
  late final String _initialTitle;
  late final String _initialSlug;
  late final String _initialCategory;
  late final String _initialSummary;
  late final String _initialContent;
  late final String _initialCoverUrl;

  Uint8List? _coverBytes;
  XFile? _coverFile;
  String? _coverUrl;
  bool _isSaving = false;

  bool get _isEditing => widget.article != null;

  bool get _hasUnsavedChanges {
    return _normalized(_titleController.text) != _normalized(_initialTitle) ||
        _normalized(_slugController.text) != _normalized(_initialSlug) ||
        _normalized(_categoryController.text) !=
            _normalized(_initialCategory) ||
        _normalized(_summaryController.text) != _normalized(_initialSummary) ||
        _normalized(_contentController.text) != _normalized(_initialContent) ||
        _normalized(_coverUrl ?? '') != _normalized(_initialCoverUrl) ||
        _coverFile != null;
  }

  @override
  void initState() {
    super.initState();
    final article = widget.article;

    _titleController = TextEditingController(text: article?.title ?? '');
    _slugController = TextEditingController(text: article?.slug ?? '');
    _categoryController = TextEditingController(text: article?.category ?? '');
    _summaryController = TextEditingController(text: article?.summary ?? '');
    _contentController = TextEditingController(text: article?.content ?? '');
    _coverUrl = article?.coverUrl;

    _initialTitle = article?.title ?? '';
    _initialSlug = article?.slug ?? '';
    _initialCategory = article?.category ?? '';
    _initialSummary = article?.summary ?? '';
    _initialContent = article?.content ?? '';
    _initialCoverUrl = article?.coverUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
    String? helper,
  }) {
    final fillColor = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final borderRadius = BorderRadius.circular(16);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 1.4,
        ),
      ),
    );
  }

  String _normalized(String value) => value.trim();

  Future<void> _maybeCloseEditor() async {
    if (_isSaving) {
      return;
    }

    if (!_hasUnsavedChanges) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppStrings.adminArticleDiscardChangesTitle,
      message: AppStrings.adminArticleDiscardChangesMessage,
      confirmLabel: AppStrings.adminArticleDiscardChangesAction,
      cancelLabel: AppStrings.cancel,
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickCover(ImageSource source) async {
    if (_isSaving) {
      return;
    }

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 84,
        maxWidth: 1800,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Image file is empty.');
      }

      if (bytes.lengthInBytes > _maxCoverBytes) {
        if (!mounted) {
          return;
        }

        context.showWarningSnackBar(
          AppStrings.adminArticleCoverTooLargeMessage(
            (_maxCoverBytes / (1024 * 1024)).round(),
          ),
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _coverFile = pickedFile;
        _coverBytes = bytes;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(
        toUserErrorMessage(
          error,
          fallback: AppStrings.tr(
            'Failed to choose image. Please try again.',
            'Gagal memilih gambar. Silakan coba lagi.',
          ),
        ),
      );
    }
  }

  void _clearCover() {
    if (_isSaving) {
      return;
    }

    setState(() {
      _coverBytes = null;
      _coverFile = null;
      _coverUrl = null;
    });
  }

  String _detectExtension(XFile file) {
    final source = (file.name.isNotEmpty ? file.name : file.path)
        .trim()
        .toLowerCase();

    if (source.endsWith('.png')) {
      return 'png';
    }
    if (source.endsWith('.webp')) {
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

  String _slugFragment(String value) {
    var normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    if (normalized.isEmpty) {
      return 'article-cover';
    }

    if (normalized.length > 40) {
      normalized = normalized.substring(0, 40);
    }

    return normalized;
  }

  Future<String> _uploadCoverImage() async {
    final file = _coverFile;
    final bytes = _coverBytes;

    if (file == null || bytes == null) {
      throw Exception('No image selected.');
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be signed in to upload image.');
    }

    final extension = _detectExtension(file);
    final contentType = _contentTypeForExtension(extension);
    final titlePart = _slugFragment(_titleController.text);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${user.id}/$titlePart-$timestamp.$extension';

    await client.storage
        .from('education-covers')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    return client.storage.from('education-covers').getPublicUrl(path);
  }

  String _coverUploadErrorMessage(Object error) {
    if (error is StorageException) {
      final lower = error.message.toLowerCase();

      if (lower.contains('bucket') && lower.contains('not found')) {
        return AppStrings.tr(
          'Cover storage is not configured yet. Please contact admin.',
          'Penyimpanan cover belum dikonfigurasi. Silakan hubungi admin.',
        );
      }

      if (lower.contains('permission') ||
          lower.contains('row-level security')) {
        return AppStrings.tr(
          'You do not have permission to upload article cover.',
          'Anda tidak memiliki izin untuk mengunggah cover artikel.',
        );
      }
    }

    return toUserErrorMessage(
      error,
      fallback: AppStrings.adminArticleCoverUploadFailedMessage,
    );
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      var coverUrl = _coverUrl?.trim();
      if (_coverFile != null && _coverBytes != null) {
        coverUrl = await _uploadCoverImage();
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        _ArticleEditorResult(
          title: _titleController.text,
          slugInput: _slugController.text,
          summary: _summaryController.text,
          content: _contentController.text,
          category: _categoryController.text,
          coverUrl: coverUrl,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      context.showErrorSnackBar(_coverUploadErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final textScaler = media.textScaler.scale(1);
    final screenWidth = media.size.width;
    final isCompact = screenWidth < 390 || textScaler > 1.1;
    final isXxs = screenWidth < 340 || textScaler > 1.25;
    final horizontalPadding = isXxs ? 12.0 : (isCompact ? 14.0 : 18.0);
    final actionPaddingBottom = media.padding.bottom > 0
        ? media.padding.bottom + 6
        : 14.0;

    return PopScope(
      canPop: !_isSaving && !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _maybeCloseEditor();
      },
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: isCompact ? 0.97 : 0.93,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isXxs ? 10 : 14,
                    horizontalPadding,
                    6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: isXxs ? 34 : (isCompact ? 38 : 42),
                        height: isXxs ? 34 : (isCompact ? 38 : 42),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit_note : Icons.auto_awesome,
                          size: isXxs ? 20 : 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: isXxs ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditing
                                  ? AppStrings.adminEditArticleTitle
                                  : AppStrings.adminCreateArticleTitle,
                              style:
                                  (isXxs
                                          ? Theme.of(
                                              context,
                                            ).textTheme.titleMedium
                                          : Theme.of(
                                              context,
                                            ).textTheme.titleLarge)
                                      ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isEditing
                                  ? AppStrings.adminEditArticleEditorSubtitle
                                  : AppStrings.adminCreateArticleEditorSubtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.68),
                                  ),
                              maxLines: isXxs ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _isSaving ? null : _maybeCloseEditor,
                        tooltip: AppStrings.close,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                if (_isSaving)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        20,
                      ),
                      children: [
                        AppCard(
                          padding: EdgeInsets.all(isXxs ? 10 : 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.image_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      AppStrings.adminArticleCoverFieldTitle,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_coverFile != null ||
                                      ((_coverUrl ?? '').trim().isNotEmpty))
                                    IconButton(
                                      onPressed: _isSaving ? null : _clearCover,
                                      tooltip: AppStrings
                                          .adminArticleCoverRemoveAction,
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: 0.35),
                                    ),
                                    child: _coverBytes != null
                                        ? Image.memory(
                                            _coverBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : ((_coverUrl ?? '').trim().isNotEmpty)
                                        ? CachedNetworkImage(
                                            imageUrl: _coverUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (context, imageUrl) =>
                                                const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                            errorWidget:
                                                (
                                                  context,
                                                  imageUrl,
                                                  error,
                                                ) => Center(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          12,
                                                        ),
                                                    child: Text(
                                                      AppStrings
                                                          .adminArticleCoverPreviewUnavailable,
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 3,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ),
                                          )
                                        : Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: isXxs ? 28 : 34,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    AppStrings
                                                        .adminArticleCoverEmptyHint,
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodySmall,
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              if (_coverFile != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _coverFile!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.72),
                                      ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                AppStrings.adminArticleCoverUploadOnSaveHint,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.72),
                                    ),
                              ),
                              const SizedBox(height: 10),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final stackActions =
                                      constraints.maxWidth < 300 || isXxs;
                                  final galleryButton = FilledButton.tonalIcon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _pickCover(ImageSource.gallery),
                                    icon: const Icon(
                                      Icons.photo_library_outlined,
                                    ),
                                    label: Text(
                                      AppStrings
                                          .adminArticleCoverSelectGalleryAction,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                  final cameraButton = OutlinedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _pickCover(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt_outlined),
                                    label: Text(
                                      AppStrings
                                          .adminArticleCoverUseCameraAction,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );

                                  if (stackActions) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        galleryButton,
                                        const SizedBox(height: 8),
                                        cameraButton,
                                      ],
                                    );
                                  }

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      galleryButton,
                                      cameraButton,
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings.adminArticleFieldTitleLabel,
                            icon: Icons.title,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _slugController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label:
                                AppStrings.adminArticleFieldSlugOptionalLabel,
                            icon: Icons.link,
                            helper: AppStrings.adminArticleSlugAutoGenerateHint,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _categoryController,
                          textInputAction: TextInputAction.next,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings
                                .adminArticleFieldCategoryOptionalLabel,
                            icon: Icons.category_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _summaryController,
                          textInputAction: TextInputAction.newline,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings
                                .adminArticleFieldSummaryOptionalLabel,
                            icon: Icons.notes_outlined,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _contentController,
                          minLines: 8,
                          maxLines: 14,
                          decoration: _fieldDecoration(
                            context,
                            label: AppStrings.adminArticleFieldContentLabel,
                            icon: Icons.article_outlined,
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return AppStrings.fieldRequired;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stackActions = constraints.maxWidth < 340 || isXxs;
                    final cancelButton = OutlinedButton(
                      onPressed: _isSaving ? null : _maybeCloseEditor,
                      child: Text(AppStrings.cancel),
                    );
                    final saveButton = FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _isSaving ? AppStrings.saving : AppStrings.save,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        8,
                        horizontalPadding,
                        actionPaddingBottom,
                      ),
                      child: stackActions
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                saveButton,
                                const SizedBox(height: 8),
                                cancelButton,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: cancelButton),
                                const SizedBox(width: 10),
                                Expanded(child: saveButton),
                              ],
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
