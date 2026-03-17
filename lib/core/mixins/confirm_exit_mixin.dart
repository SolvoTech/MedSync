import 'package:flutter/material.dart';

import '../widgets/app_dialog.dart';

/// Mixin to confirm before exiting a form with unsaved changes.
/// Per spec §26.3.
mixin ConfirmExitMixin<T extends StatefulWidget> on State<T> {
  /// Override to indicate if there are unsaved changes.
  bool get hasUnsavedChanges;

  /// Intercept back navigation.
  Future<bool> onWillPop() async {
    if (!hasUnsavedChanges) return true;

    final confirmed = await AppDialog.showConfirm(
      context,
      title: 'Keluar tanpa menyimpan?',
      message: 'Perubahan yang belum disimpan akan hilang.',
      confirmLabel: 'Keluar',
      isDestructive: true,
    );

    return confirmed ?? false;
  }

  /// Wrap your Scaffold with this to enable back confirmation.
  Widget wrapWithPopScope({required Widget child}) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: child,
    );
  }
}
