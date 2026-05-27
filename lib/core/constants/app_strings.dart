class AppStrings {
  const AppStrings._();

  static String _languageCode = 'id';

  static void setLanguageCode(String value) {
    _languageCode = value == 'id' ? 'id' : 'en';
  }

  static String get languageCode => _languageCode;

  static bool get _isId => _languageCode == 'id';

  static String _t(String en, String id) => _isId ? id : en;
  static String tr(String en, String id) => _t(en, id);

  // App
  static String get appName => 'MEDISNA';
  static String get appTagline => 'Your Personal Health Companion';
  static String get loading => _t('Loading...', 'Memuat...');
  static String get errorGeneral => _t(
    'Something went wrong. Please try again.',
    'Terjadi kesalahan. Silakan coba lagi.',
  );
  static String get noInternet =>
      _t('No internet connection', 'Tidak ada koneksi internet');
  static String get emptyData => _t('No data yet', 'Belum ada data');

  // Splash
  static String get splashTitle => 'MEDISNA';
  static String get splashSubtitle => 'Your Personal Health Companion';

  // Auth
  static String get loginTitle => _t('Welcome Back', 'Selamat Datang');
  static String get loginSubtitle =>
      _t('Sign in to your MEDISNA account', 'Masuk ke akun MEDISNA Anda');
  static String get loginGreeting => _t(
    'Hello, wishing you a healthy day.',
    'Halo, semoga harimu sehat hari ini.',
  );
  static String get registerTitle => _t('Create New Account', 'Buat Akun Baru');
  static String get registerSubtitle => _t(
    'Register to start using MEDISNA',
    'Daftar untuk mulai menggunakan MEDISNA',
  );
  static String get registerGreeting =>
      _t('Let us start your healthy journey.', 'Yuk mulai perjalanan sehatmu.');
  static String get forgotPasswordTitle =>
      _t('Forgot Password', 'Lupa Kata Sandi');
  static String get forgotPasswordGreeting => _t(
    'Do not worry, we will help reset your account.',
    'Tenang, kami bantu reset akun Anda.',
  );
  static String get usernameLabel => _t('Username', 'Username');
  static String get emailLabel => _t('Email Address', 'Alamat Email');
  static String get passwordLabel => _t('Password', 'Kata Sandi');
  static String get confirmPasswordLabel =>
      _t('Confirm Password', 'Konfirmasi Kata Sandi');
  static String get loginButton => _t('Sign In', 'Masuk');
  static String get registerButton => _t('Register', 'Daftar');
  static String get forgotPassword =>
      _t('Forgot password?', 'Lupa kata sandi?');
  static String get noAccount =>
      _t("Don't have an account? ", 'Belum punya akun? ');
  static String get hasAccount =>
      _t('Already have an account? ', 'Sudah punya akun? ');
  static String get registerLink => _t('Register', 'Daftar');
  static String get loginLink => _t('Sign In', 'Masuk');
  static String get resetPasswordButton =>
      _t('Send Reset Link', 'Kirim Link Reset');
  static String get resetPasswordSuccess => _t(
    'Reset link has been sent to your email.',
    'Link reset telah dikirim ke email Anda.',
  );
  static String get loginFailed => _t(
    'Failed to sign in. Check your username and password.',
    'Gagal masuk. Periksa username dan kata sandi Anda.',
  );
  static String get registerSuccess => _t(
    'Registration successful. Please sign in with your new username.',
    'Pendaftaran berhasil. Silakan masuk dengan username baru Anda.',
  );
  static String get registerFailed => _t(
    'Failed to register. Please try again.',
    'Gagal mendaftar. Silakan coba lagi.',
  );
  static String get resetPasswordEmailSent => _t(
    'Password reset instructions have been sent.',
    'Instruksi reset kata sandi telah dikirim.',
  );
  static String get resetPasswordFailed => _t(
    'Failed to send reset email. Please try again.',
    'Gagal mengirim email reset. Silakan coba lagi.',
  );
  static String get resetPasswordInstruction => _t(
    'Enter your username to receive password reset instructions.',
    'Masukkan username Anda untuk menerima instruksi reset kata sandi.',
  );
  static String get rememberPasswordPrompt =>
      _t('Remember your password? ', 'Sudah ingat kata sandi? ');
  static String get completeProfileTitle =>
      _t('Complete Profile', 'Lengkapi Profil');
  static String get basicProfileTitle => _t('Basic Profile', 'Profil Dasar');
  static String get basicProfileSubtitle => _t(
    'Help us set up a more personalized experience.',
    'Bantu kami menyiapkan pengalaman yang lebih personal.',
  );
  static String get birthDateOptional =>
      _t('Birth Date (Optional)', 'Tanggal Lahir (Opsional)');
  static String get notSelected => _t('Not selected', 'Belum dipilih');
  static String get saving => _t('Saving...', 'Menyimpan...');
  static String get saveProfile => _t('Save Profile', 'Simpan Profil');
  static String get saveProfileFailed => _t(
    'Failed to save profile. Please try again.',
    'Gagal menyimpan profil. Silakan coba lagi.',
  );

  // Home
  static String get homeTitle => _t('Home', 'Beranda');
  static String get homeGreetingMorning => _t('Good Morning', 'Selamat Pagi');
  static String get homeGreetingAfternoon =>
      _t('Good Afternoon', 'Selamat Siang');
  static String get homeGreetingEvening => _t('Good Evening', 'Selamat Sore');
  static String get homeGreetingNight => _t('Good Night', 'Selamat Malam');
  static String get todayTasks => _t('Today\'s Tasks', 'Tugas Hari Ini');
  static String get todaySummary =>
      _t('Today\'s Summary', 'Ringkasan Hari Ini');
  static String get streakDays => _t('days in a row', 'hari berturut-turut');
  static String get allTasksDone =>
      _t('All tasks completed! 🎉', 'Semua tugas selesai! 🎉');
  static String get noTasksToday =>
      _t('No tasks for today yet.', 'Belum ada tugas untuk hari ini.');
  static String get upcomingReminder =>
      _t('Upcoming Reminder', 'Pengingat Berikutnya');
  static String get completedLabel => _t('Completed', 'Selesai');
  static String get progressLabel => _t('Progress', 'Progres');
  static String get tasksLoadFailed => _t(
    'Failed to load today\'s tasks. Please try again.',
    'Gagal memuat tugas hari ini. Silakan coba lagi.',
  );
  static String get firstDayMotivation =>
      _t('Start your first day today!', 'Mulai hari pertamamu hari ini!');

  // Bottom nav
  static String get scheduleTitle => _t('Schedule', 'Jadwal');
  static String get reportTitle => _t('Reports', 'Laporan');
  static String get articleTitle => _t('Articles', 'Artikel');
  static String get notificationTitle => _t('Notifications', 'Notifikasi');
  static String get profileTitle => _t('Profile', 'Profil');

  // Admin
  static String get adminHomeTitle => _t('Admin Home', 'Beranda Admin');
  static String get adminDashboardNavLabel => _t('Dashboard', 'Dashboard');
  static String get adminUsersTitle => _t('Users', 'Pengguna');
  static String get adminContentTitle => _t('Content', 'Konten');
  static String get adminControlCenterTitle =>
      _t('Admin Control Center', 'Pusat Kontrol Admin');
  static String get adminRefreshTooltip => _t('Refresh', 'Muat Ulang');
  static String get adminBadge => _t('ADMIN', 'ADMIN');
  static String get adminControlHubTitle => _t('Control Hub', 'Pusat Kendali');
  static String get adminControlHubSubtitle => _t(
    'Admin workspace to monitor users and maintain educational content.',
    'Ruang kerja admin untuk memantau pengguna dan mengelola konten edukasi.',
  );
  static String get adminQuickAccessTitle => _t('Quick Access', 'Akses Cepat');
  static String get adminQuickAccessSubtitle => _t(
    'Open control modules directly from dashboard.',
    'Buka modul kontrol langsung dari dashboard.',
  );
  static String get adminUserManagementTitle =>
      _t('User Management', 'Manajemen Pengguna');
  static String get adminUserManagementHint => _t(
    'Suspend, activate, and reset user account access.',
    'Nonaktifkan, aktifkan, dan reset akses akun pengguna.',
  );
  static String get adminUserManagementSubtitle => _t(
    'Activate, suspend, or reset user access securely.',
    'Aktifkan, nonaktifkan, atau reset akses pengguna dengan aman.',
  );
  static String get adminUserFilterTitle =>
      _t('Filter Users', 'Filter Pengguna');
  static String get adminUserSearchHint => _t(
    'Search by name, username, or internal email',
    'Cari berdasarkan nama, username, atau email internal',
  );
  static String get adminUserFilterStatusLabel =>
      _t('Account Status', 'Status Akun');
  static String get adminUserFilterRoleLabel => _t('Role', 'Peran');
  static String get adminUserFilterAllLabel => _t('All', 'Semua');
  static String get adminUserFilterActiveLabel => _t('Active', 'Aktif');
  static String get adminUserFilterSuspendedLabel =>
      _t('Suspended', 'Dinonaktifkan');
  static String get adminUserFilterAdminLabel => _t('Admin', 'Admin');
  static String get adminUserFilterUserLabel => _t('User', 'Pengguna');
  static String adminUserFilterResultSummary({
    required int shown,
    required int total,
  }) => _t(
    'Showing $shown of $total users.',
    'Menampilkan $shown dari $total pengguna.',
  );
  static String get adminNoFilteredUserMessage => _t(
    'No users match the current filter.',
    'Tidak ada pengguna yang sesuai dengan filter saat ini.',
  );
  static String get adminNoFilteredUserSubtitle => _t(
    'Adjust search or filter chips to view users.',
    'Ubah kata kunci atau chip filter untuk menampilkan pengguna.',
  );
  static String get adminBulkActionTitle => _t('Bulk Actions', 'Aksi Massal');
  static String adminBulkSelectionSummary({
    required int selectedCount,
    required int suspendCandidateCount,
    required int activateCandidateCount,
  }) => _t(
    '$selectedCount selected. $suspendCandidateCount can be suspended, $activateCandidateCount can be activated.',
    '$selectedCount dipilih. $suspendCandidateCount bisa dinonaktifkan, $activateCandidateCount bisa diaktifkan.',
  );
  static String get adminBulkSelectAllAction =>
      _t('Select All Filtered', 'Pilih Semua Tersaring');
  static String get adminBulkClearSelectionAction =>
      _t('Clear Selection', 'Bersihkan Pilihan');
  static String get adminBulkSuspendAction =>
      _t('Suspend Selected', 'Nonaktifkan Terpilih');
  static String get adminBulkActivateAction =>
      _t('Activate Selected', 'Aktifkan Terpilih');
  static String get adminBulkNoEligibleSelection => _t(
    'No eligible users in current selection for this action.',
    'Tidak ada pengguna yang memenuhi syarat pada pilihan saat ini untuk aksi ini.',
  );
  static String adminBulkSuspendTitle(int count) => _t(
    'Suspend $count selected users?',
    'Nonaktifkan $count pengguna terpilih?',
  );
  static String adminBulkActivateTitle(int count) => _t(
    'Activate $count selected users?',
    'Aktifkan $count pengguna terpilih?',
  );
  static String adminBulkSuspendMessage(int count) => _t(
    '$count selected users will be unable to sign in until reactivated.',
    '$count pengguna terpilih tidak akan bisa masuk sampai diaktifkan kembali.',
  );
  static String adminBulkActivateMessage(int count) => _t(
    '$count selected users will be able to sign in again.',
    '$count pengguna terpilih akan bisa masuk kembali.',
  );
  static String adminBulkStatusResult({
    required int successCount,
    required int failedCount,
  }) => _t(
    'Bulk update finished. Success: $successCount, Failed: $failedCount.',
    'Update massal selesai. Berhasil: $successCount, Gagal: $failedCount.',
  );
  static String get adminBulkActionFailed => _t(
    'Bulk update failed. Please try again.',
    'Update massal gagal. Silakan coba lagi.',
  );
  static String adminLastSyncLabel(String dateTimeLabel) =>
      _t('Last synced: $dateTimeLabel', 'Sinkron terakhir: $dateTimeLabel');
  static String get adminContentManagementTitle =>
      _t('Content Management', 'Manajemen Konten');
  static String get adminContentManagementHint => _t(
    'Draft and publish educational content for users.',
    'Buat draf dan publikasikan konten edukasi untuk pengguna.',
  );
  static String get adminSystemSnapshotTitle =>
      _t('System Snapshot', 'Ringkasan Sistem');
  static String get adminSystemOverviewSubtitle => _t(
    'Daily platform overview for admin decisions.',
    'Gambaran harian platform untuk keputusan admin.',
  );
  static String get adminSystemSnapshotSubtitle => _t(
    'Quick metrics for users and daily adherence.',
    'Metrik cepat pengguna dan kepatuhan harian.',
  );
  static String get adminMetricTotalUsers =>
      _t('Total Users', 'Total Pengguna');
  static String get adminMetricActiveUsers =>
      _t('Active Users', 'Pengguna Aktif');
  static String get adminMetricSuspendedUsers =>
      _t('Suspended Users', 'Pengguna Dinonaktifkan');
  static String get adminMetricAdminAccounts =>
      _t('Admin Accounts', 'Akun Admin');
  static String get adminMetricAdherenceToday =>
      _t('Adherence Today', 'Kepatuhan Hari Ini');
  static String get adminManageLabel => _t('Manage', 'Kelola');
  static String get adminManageEducationHint => _t(
    'Manage educational articles for users.',
    'Kelola artikel edukasi untuk pengguna.',
  );
  static String get adminContentWorkspaceTitle =>
      _t('Content Workspace', 'Ruang Kelola Konten');
  static String get adminArticleCollectionTitle =>
      _t('Article Collection', 'Koleksi Artikel');
  static String get adminManageArticlesTitle =>
      _t('Manage Articles', 'Kelola Artikel');
  static String get adminAddArticleTooltip =>
      _t('Add Article', 'Tambah Artikel');
  static String get adminNewArticleButton => _t('New Article', 'Artikel Baru');
  static String get adminNoAccessMessage => _t(
    'You do not have access to this admin page.',
    'Anda tidak memiliki akses ke halaman admin.',
  );
  static String get adminNoAccessSubtitle => _t(
    'Contact your administrator if this is unexpected.',
    'Hubungi administrator jika ini tidak sesuai.',
  );
  static String get adminControlCenterIntroSubtitle => _t(
    'Monitor account access, user status, and today\'s adherence from one dashboard.',
    'Pantau akses akun, status pengguna, dan kepatuhan hari ini dari satu dashboard.',
  );
  static String get adminNoUserDataMessage =>
      _t('No user data available yet.', 'Belum ada data pengguna.');
  static String get adminNoUserDataSubtitle =>
      _t('User data will appear here.', 'Data pengguna akan tampil di sini.');
  static String get adminSuspendAccountTitle =>
      _t('Suspend account?', 'Nonaktifkan akun?');
  static String get adminActivateAccountTitle =>
      _t('Activate account?', 'Aktifkan akun?');
  static String get adminSuspendAccountMessage => _t(
    'The user will not be able to sign in while suspended.',
    'Pengguna tidak bisa masuk selama status dinonaktifkan.',
  );
  static String get adminActivateAccountMessage => _t(
    'The user will be able to sign in again.',
    'Pengguna akan bisa masuk kembali.',
  );
  static String get adminSuspendAction => _t('Suspend', 'Nonaktifkan');
  static String get adminActivateAction => _t('Activate', 'Aktifkan');
  static String get adminUserSuspendedSuccess =>
      _t('User account suspended.', 'Akun pengguna dinonaktifkan.');
  static String get adminUserActivatedSuccess =>
      _t('User account reactivated.', 'Akun pengguna diaktifkan kembali.');
  static String get adminResetUserAccessTitle =>
      _t('Reset user access?', 'Reset akses pengguna?');
  static String get adminResetUserAccessMessage => _t(
    'Reset instructions will be sent via the registered internal account channel.',
    'Instruksi reset akan dikirim melalui kanal akun internal yang terdaftar.',
  );
  static String get adminSendResetAction => _t('Send Reset', 'Kirim Reset');
  static String get adminResetAccessSuccess => _t(
    'Reset access instructions sent successfully.',
    'Instruksi reset akses berhasil dikirim.',
  );
  static String get adminUnknownName => _t('No Name', 'Tanpa Nama');
  static String get adminStatusSuspended => _t('SUSPENDED', 'DINONAKTIFKAN');
  static String get adminStatusActive => _t('ACTIVE', 'AKTIF');
  static String get adminResetAccessButton => _t('Reset Access', 'Reset Akses');
  static String get adminViewActivityButton =>
      _t('View Activity', 'Lihat Aktivitas');
  static String get adminUserActivityTitle =>
      _t('User Activity Detail', 'Detail Aktivitas Pengguna');
  static String get adminUserActivityInvalidUser =>
      _t('Invalid user selected.', 'Pengguna yang dipilih tidak valid.');
  static String get adminUserActivityInvalidUserHint => _t(
    'Please return to user list and choose a valid account.',
    'Silakan kembali ke daftar pengguna dan pilih akun yang valid.',
  );
  static String adminUserActivityProfileSubtitle({
    required String username,
    required String status,
  }) => _t(
    '@$username • Account status: $status',
    '@$username • Status akun: $status',
  );
  static String get adminUserActivityPeriodSectionTitle =>
      _t('Adherence Period', 'Periode Kepatuhan');
  static String get adminAdherenceStrictHint => _t(
    'Strict adherence uses done / total schedule.',
    'Kepatuhan strict memakai selesai / total jadwal.',
  );
  static String get adminPeriodToday => _t('Today', 'Hari Ini');
  static String get adminPeriodLast7Days => _t('Last 7 Days', '7 Hari');
  static String get adminPeriodLast30Days => _t('Last 30 Days', '30 Hari');
  static String adminUserActivityRangeLabel(String range) =>
      _t('Range: $range', 'Rentang: $range');
  static String get adminUserActivityOverallAdherence =>
      _t('Overall', 'Keseluruhan');
  static String get adminUserActivityMedicineAdherence =>
      _t('Medicine', 'Obat');
  static String get adminUserActivityMeasurementAdherence =>
      _t('Measurement', 'Pengukuran');
  static String get adminUserActivityActivityAdherence =>
      _t('Activity', 'Aktivitas');
  static String adminUserActivityDoneOfTotal({
    required int done,
    required int total,
  }) => _t('$done done of $total', '$done selesai dari $total');
  static String get adminTaskProofSection =>
      _t('Completion Proofs', 'Bukti Penyelesaian');
  static String get adminTaskProofSectionHint => _t(
    'Review user-submitted photos for completed in-app tasks.',
    'Pantau foto bukti yang dikirim pengguna saat menyelesaikan tugas di aplikasi.',
  );
  static String get adminTaskProofEmpty => _t(
    'No completed task proof found in this period.',
    'Belum ada bukti tugas selesai pada periode ini.',
  );
  static String get adminTaskProofAvailable =>
      _t('Photo proof available', 'Bukti foto tersedia');
  static String get adminTaskProofMissing =>
      _t('No photo proof', 'Tanpa bukti foto');
  static String get adminTaskProofOpen => _t('Open proof', 'Buka bukti');
  static String get adminUserActivityMedicineSection =>
      _t('Medicine Schedules', 'Jadwal Obat');
  static String get adminUserActivityMedicineSectionHint => _t(
    'Monitor medicine schedule adherence per plan.',
    'Pantau kepatuhan jadwal obat per rencana.',
  );
  static String get adminUserActivityMeasurementSection =>
      _t('Measurement Schedules', 'Jadwal Pengukuran');
  static String get adminUserActivityMeasurementSectionHint => _t(
    'Monitor measurement reminder adherence per schedule.',
    'Pantau kepatuhan pengingat pengukuran per jadwal.',
  );
  static String get adminUserActivityActivitySection =>
      _t('Activity Schedules', 'Jadwal Aktivitas');
  static String get adminUserActivityActivitySectionHint => _t(
    'Monitor physical activity adherence per schedule.',
    'Pantau kepatuhan aktivitas fisik per jadwal.',
  );
  static String get adminUserActivityNoMedicineSchedule => _t(
    'No medicine schedules found for this user.',
    'Tidak ada jadwal obat untuk pengguna ini.',
  );
  static String get adminUserActivityNoMeasurementSchedule => _t(
    'No measurement schedules found for this user.',
    'Tidak ada jadwal pengukuran untuk pengguna ini.',
  );
  static String get adminUserActivityNoActivitySchedule => _t(
    'No activity schedules found for this user.',
    'Tidak ada jadwal aktivitas untuk pengguna ini.',
  );
  static String get adminUserActivityMedicineSubtitle =>
      _t('Medicine Schedule', 'Jadwal Obat');
  static String adminUserActivityTimeLabel(String value) =>
      _t('Time: $value', 'Waktu: $value');
  static String get adminUserActivityScheduleActive =>
      _t('Active Schedule', 'Jadwal Aktif');
  static String get adminUserActivityScheduleInactive =>
      _t('Inactive Schedule', 'Jadwal Nonaktif');
  static String get adminResetAccessUnavailableHint => _t(
    'Reset access is only available for users with a valid internal account email.',
    'Reset akses hanya tersedia untuk pengguna dengan email akun internal yang valid.',
  );
  static String get adminSelfAccountHint => _t(
    'This account is your own account.',
    'Akun ini adalah akun Anda sendiri.',
  );
  static String get adminOtherAdminHint => _t(
    'Other admin accounts cannot be managed from this screen.',
    'Akun admin lain tidak bisa dikelola dari layar ini.',
  );
  static String get adminEducationWorkspaceDraftSubtitle => _t(
    'Draft, publish, and update educational content shown to users.',
    'Buat draf, publikasikan, dan perbarui konten edukasi untuk pengguna.',
  );
  static String get adminEducationWorkspaceReviewSubtitle => _t(
    'Review and publish educational articles with one tap.',
    'Tinjau dan publikasikan artikel edukasi dalam satu sentuhan.',
  );
  static String get adminArticleCollectionLoadingSubtitle =>
      _t('Loading article records...', 'Memuat data artikel...');
  static String get adminArticleCollectionManageSubtitle => _t(
    'Manage draft and published content.',
    'Kelola konten draf dan yang sudah terbit.',
  );
  static String get adminNoEducationArticleMessage =>
      _t('No educational articles yet.', 'Belum ada artikel edukasi.');
  static String get adminNoEducationArticleSubtitle => _t(
    'Create your first article for users.',
    'Buat artikel pertama untuk pengguna.',
  );
  static String get adminArticlePublishedChip => _t('PUBLISHED', 'TERBIT');
  static String get adminArticleDraftChip => _t('DRAFT', 'DRAF');
  static String get adminCreateArticleTitle =>
      _t('Create Article', 'Buat Artikel');
  static String get adminEditArticleTitle => _t('Edit Article', 'Edit Artikel');
  static String get adminCreateArticleEditorSubtitle => _t(
    'Craft educational content with a polished layout and cover image.',
    'Susun konten edukasi dengan tampilan rapi dan gambar sampul.',
  );
  static String get adminEditArticleEditorSubtitle => _t(
    'Refine article details and keep your content up to date.',
    'Perbarui detail artikel agar konten selalu relevan.',
  );
  static String get adminArticleTitleRequiredMessage =>
      _t('Title and content are required.', 'Judul dan konten wajib diisi.');
  static String get adminArticleCreatedSuccess =>
      _t('Article created.', 'Artikel berhasil dibuat.');
  static String get adminArticleUpdatedSuccess =>
      _t('Article updated.', 'Artikel berhasil diperbarui.');
  static String get adminArticleSlugAlreadyUsedMessage => _t(
    'This slug is already used by another article.',
    'Slug ini sudah digunakan artikel lain.',
  );
  static String get adminArticleDiscardChangesTitle =>
      _t('Discard unsaved changes?', 'Buang perubahan yang belum disimpan?');
  static String get adminArticleDiscardChangesMessage => _t(
    'Your latest edits will be lost if you leave now.',
    'Perubahan terakhir Anda akan hilang jika keluar sekarang.',
  );
  static String get adminArticleDiscardChangesAction => _t('Discard', 'Buang');
  static String get adminUnpublishArticleTitle =>
      _t('Unpublish article?', 'Batalkan publikasi artikel?');
  static String get adminPublishArticleTitle =>
      _t('Publish article?', 'Publikasikan artikel?');
  static String get adminUnpublishArticleMessage => _t(
    'This article will no longer be visible to users.',
    'Artikel tidak akan terlihat oleh pengguna.',
  );
  static String get adminPublishArticleMessage => _t(
    'This article will be visible to users immediately.',
    'Artikel akan langsung terlihat oleh pengguna.',
  );
  static String get adminUnpublishAction =>
      _t('Unpublish', 'Batalkan Publikasi');
  static String get adminPublishAction => _t('Publish', 'Publikasikan');
  static String get adminArticleUnpublishedSuccess => _t(
    'Article unpublished successfully.',
    'Publikasi artikel berhasil dibatalkan.',
  );
  static String get adminArticlePublishedSuccess =>
      _t('Article published successfully.', 'Artikel berhasil dipublikasikan.');
  static String get adminDeleteArticleTitle =>
      _t('Delete article?', 'Hapus artikel?');
  static String get adminDeleteArticleMessage => _t(
    'Deleted articles cannot be restored.',
    'Artikel yang dihapus tidak dapat dikembalikan.',
  );
  static String get adminArticleDeletedSuccess =>
      _t('Article deleted.', 'Artikel berhasil dihapus.');
  static String get adminArticleFieldTitleLabel => _t('Title', 'Judul');
  static String get adminArticleFieldSlugOptionalLabel =>
      _t('Slug (optional)', 'Slug (opsional)');
  static String get adminArticleSlugAutoGenerateHint => _t(
    'Leave blank to auto-generate from title.',
    'Biarkan kosong untuk dibuat otomatis dari judul.',
  );
  static String get adminArticleFieldCategoryOptionalLabel =>
      _t('Category (optional)', 'Kategori (opsional)');
  static String get adminArticleFieldCoverUrlOptionalLabel =>
      _t('Cover Image (optional)', 'Gambar Sampul (opsional)');
  static String get adminArticleCoverFieldTitle =>
      _t('Cover Image', 'Gambar Sampul');
  static String get adminArticleCoverSelectGalleryAction =>
      _t('Gallery', 'Galeri');
  static String get adminArticleCoverUseCameraAction => _t('Camera', 'Kamera');
  static String get adminArticleCoverRemoveAction => _t('Remove', 'Hapus');
  static String get adminArticleCoverEmptyHint => _t(
    'Add a cover image to make the article more engaging.',
    'Tambahkan gambar sampul agar artikel lebih menarik.',
  );
  static String get adminArticleCoverPreviewUnavailable =>
      _t('Preview unavailable', 'Pratinjau tidak tersedia');
  static String get adminArticleCoverUploadOnSaveHint => _t(
    'JPG, PNG, or WebP. Cover will be uploaded when you tap Save.',
    'JPG, PNG, atau WebP. Sampul akan diunggah saat menekan Simpan.',
  );
  static String get adminArticleCoverUploadFailedMessage => _t(
    'Failed to upload cover image. Please try again.',
    'Gagal mengunggah gambar sampul. Silakan coba lagi.',
  );
  static String adminArticleCoverTooLargeMessage(int maxMb) => _t(
    'Image is too large. Maximum file size is ${maxMb}MB.',
    'Ukuran gambar terlalu besar. Maksimal ${maxMb}MB.',
  );
  static String get adminArticleFieldSummaryOptionalLabel =>
      _t('Summary (optional)', 'Ringkasan (opsional)');
  static String get adminArticleFieldContentLabel => _t('Content', 'Konten');

  static String adminTodayAdherenceSummary({
    required int completed,
    required int total,
    required int percent,
  }) => _t(
    'Today task adherence: $completed/$total ($percent%)',
    'Kepatuhan tugas hari ini: $completed/$total ($percent%)',
  );

  static String adminCreatedAtLabel(String dateLabel) =>
      _t('Created: $dateLabel', 'Dibuat: $dateLabel');

  static String adminArticleMetaLabel({
    required String slug,
    required String updatedDate,
  }) => _t(
    'Slug: $slug | Updated: $updatedDate',
    'Slug: $slug | Update: $updatedDate',
  );

  // Medicine
  static String get addMedicine => _t('Add Medicine', 'Tambah Obat');
  static String get editMedicine => _t('Edit Medicine', 'Edit Obat');
  static String get medicineName => _t('Medicine Name', 'Nama Obat');
  static String get medicineDosage => _t('Dosage', 'Dosis');
  static String get medicineType => _t('Medicine Type', 'Jenis Obat');
  static String get medicineStock => _t('Current Stock', 'Stok Saat Ini');
  static String get medicineUnit => _t('Stock Unit', 'Satuan Stok');
  static String get scheduleFormTitle =>
      _t('Medication Schedule', 'Jadwal Minum');
  static String get addTimeSlot => _t('Add Time', 'Tambah Waktu Minum');
  static String get deleteScheduleConfirm =>
      _t('Delete this schedule?', 'Hapus jadwal ini?');
  static String get medicineAdded =>
      _t('Medicine added.', 'Obat berhasil ditambahkan.');
  static String get medicineDeleted =>
      _t('Medicine deleted.', 'Obat berhasil dihapus.');
  static String get scheduleAdded =>
      _t('Schedule added.', 'Jadwal berhasil ditambahkan.');
  static String get scheduleDeleted =>
      _t('Schedule deleted.', 'Jadwal berhasil dihapus.');

  // Measurement
  static String get addMeasurement =>
      _t('Add Measurement', 'Tambah Pengukuran');
  static String get editMeasurement =>
      _t('Edit Measurement', 'Edit Pengukuran');
  static String get measurementType =>
      _t('Measurement Type', 'Tipe Pengukuran');

  // Physical Activity
  static String get addActivity => _t('Add Activity', 'Tambah Aktivitas');
  static String get editActivity => _t('Edit Activity', 'Edit Aktivitas');
  static String get activityType => _t('Activity Type', 'Tipe Aktivitas');

  // Task
  static String get taskDone =>
      _t('Task marked as done.', 'Task ditandai selesai.');
  static String get taskSkipped => _t('Task skipped.', 'Task dilewati.');
  static String get taskProofPreviewTitle =>
      _t('Completion Proof', 'Bukti Selesai');
  static String get taskProofPreviewHint => _t(
    'This photo will be saved as admin evidence. It is not used to validate the task content.',
    'Foto ini akan disimpan sebagai bukti untuk admin. Foto tidak digunakan untuk validasi isi tugas.',
  );
  static String get taskProofRetakeAction => _t('Retake', 'Ulangi');
  static String get taskProofUseAction => _t('Use', 'Gunakan');
  static String get taskProofRequiredMessage => _t(
    'Photo proof is required before marking this task done.',
    'Bukti foto wajib disertakan sebelum menandai tugas selesai.',
  );

  // Notifications
  static String get markAllRead =>
      _t('Mark All as Read', 'Tandai Semua Dibaca');
  static String get noNotifications =>
      _t('No notifications yet.', 'Belum ada notifikasi.');

  // Profile
  static String get editProfile => _t('Edit Profile', 'Edit Profil');
  static String get fullNameLabel => _t('Full Name', 'Nama Lengkap');
  static String get birthDateLabel => _t('Birth Date', 'Tanggal Lahir');
  static String get changePassword => _t('Change Password', 'Ganti Kata Sandi');
  static String get notificationSettings =>
      _t('Notification Settings', 'Pengaturan Notifikasi');
  static String get appearance => _t('Appearance & Theme', 'Tampilan & Tema');
  static String get dataManagement => _t('Data & Backup', 'Data & Cadangan');
  static String get about => _t('About MEDISNA', 'Tentang MEDISNA');
  static String get privacyPolicy => _t('Privacy Policy', 'Kebijakan Privasi');
  static String get termsConditions =>
      _t('Terms & Conditions', 'Syarat & Ketentuan');
  static String get helpSupport => _t('Help & Support', 'Bantuan & Dukungan');
  static String get logout => _t('Log Out', 'Keluar');
  static String get deleteAccount => _t('Delete Account', 'Hapus Akun');

  // General
  static String get save => _t('Save', 'Simpan');
  static String get cancel => _t('Cancel', 'Batal');
  static String get delete => _t('Delete', 'Hapus');
  static String get edit => _t('Edit', 'Edit');
  static String get close => _t('Close', 'Tutup');
  static String get next => _t('Next', 'Lanjut');
  static String get back => _t('Back', 'Kembali');
  static String get skip => _t('Skip', 'Lewati');
  static String get done => _t('Done', 'Selesai');
  static String get retry => _t('Retry', 'Coba Lagi');
  static String get confirm => _t('Confirm', 'Konfirmasi');
  static String get yes => _t('Yes', 'Ya');
  static String get no => _t('No', 'Tidak');

  // Validation
  static String get fieldRequired =>
      _t('This field is required', 'Bidang ini wajib diisi');
  static String get emailInvalid =>
      _t('Invalid email format', 'Format email tidak valid');
  static String get usernameRequired =>
      _t('Username is required', 'Username wajib diisi');
  static String get usernameInvalid => _t(
    'Username must be 3-24 characters using lowercase letters, numbers, or underscore',
    'Username harus 3-24 karakter menggunakan huruf kecil, angka, atau underscore',
  );
  static String get passwordTooShort => _t(
    'Password must be at least 8 characters',
    'Kata sandi minimal 8 karakter',
  );
  static String get passwordMismatch =>
      _t('Passwords do not match', 'Kata sandi tidak cocok');
  static String get nameRequired =>
      _t('Name cannot be empty', 'Nama tidak boleh kosong');

  // Schedule module
  static String get noMedicineData =>
      _t('No medicine data yet.', 'Belum ada data obat.');
  static String get activeSchedules => _t('Active Schedules', 'Jadwal Aktif');
  static String get inactiveSchedules =>
      _t('Inactive Schedules', 'Jadwal Nonaktif');
  static String get disableMedicineSchedule =>
      _t('Disable Medicine Schedule', 'Nonaktifkan Jadwal Obat');
  static String get disableKeepsVisible => _t(
    'Still visible, but reminders are paused.',
    'Tetap tampil, tapi pengingat dihentikan.',
  );
  static String get reactivate => _t('Reactivate', 'Aktifkan Kembali');
  static String get reactivateHint => _t(
    'Schedule will run again and reminders resume.',
    'Jadwal aktif lagi dan pengingat berjalan.',
  );
  static String get deletePermanent =>
      _t('Delete Permanently', 'Hapus Permanen');
  static String get dataWillBeDeleted =>
      _t('Data will be deleted permanently.', 'Data akan dihapus sepenuhnya.');
  static String get disableMedicineTitle =>
      _t('Disable Medicine Schedule?', 'Nonaktifkan Jadwal Obat?');
  static String get disableAction => _t('Disable', 'Nonaktifkan');
  static String get deleteMedicineTitle =>
      _t('Delete Medicine Permanently?', 'Hapus Obat Permanen?');
  static String get actionFailed =>
      _t('Action failed. Please try again.', 'Aksi gagal. Silakan coba lagi.');
  static String get medicineStatusDisabledInfo => _t(
    'This medicine is currently inactive. Schedule remains visible, but reminders are paused until reactivated.',
    'Obat ini sedang nonaktif. Jadwal tetap ditampilkan, tetapi pengingat tidak berjalan sampai diaktifkan kembali.',
  );
  static String get noScheduleForMedicine => _t(
    'No schedules for this medicine yet.',
    'Belum ada jadwal untuk obat ini.',
  );
  static String get scheduleLoadFailed => _t(
    'Failed to load schedule. Please try again.',
    'Gagal memuat jadwal. Silakan coba lagi.',
  );
  static String get addMedicineTimeSchedule =>
      _t('Add Medication Time', 'Tambah Jadwal Minum');
  static String get activateFailed => _t(
    'Failed to reactivate medicine schedule. Please try again.',
    'Gagal mengaktifkan jadwal obat. Silakan coba lagi.',
  );
  static String get deleteScheduleTitle =>
      _t('Delete Schedule?', 'Hapus Jadwal?');
  static String get deleteScheduleMessage => _t(
    'Medicine schedule will be permanently deleted and related reminders canceled.',
    'Jadwal obat akan dihapus permanen dan notifikasi terkait dibatalkan.',
  );
  static String get deleteScheduleFailed => _t(
    'Failed to delete schedule. Please try again.',
    'Gagal menghapus jadwal. Silakan coba lagi.',
  );
  static String get medicineDetailTitlePrefix => _t('Schedule', 'Jadwal');
  static String get dosageNotSet => _t('Dosage not set', 'Dosis belum diisi');
  static String get stockLabel => _t('Stock', 'Stok');
  static String get statusActive => _t('Active', 'Aktif');
  static String get statusInactive => _t('Inactive', 'Nonaktif');
  static String get statusActiveLabel => _t('Active status', 'Status aktif');
  static String get statusInactiveLabel =>
      _t('Inactive status', 'Status nonaktif');

  // Forms
  static String get addMedicineSheetTitle => _t('Add Medicine', 'Tambah Obat');
  static String get addMedicineSheetSubtitle => _t(
    'Save medicine details to keep schedule and stock organized.',
    'Simpan data obat agar jadwal dan stok lebih teratur.',
  );
  static String get medicinePhotoOptional =>
      _t('Package Photo\n(Optional)', 'Foto Kemasan\n(Opsional)');
  static String get medicineAddFailed => _t(
    'Failed to add medicine. Please try again.',
    'Gagal menambahkan obat. Silakan coba lagi.',
  );
  static String get scheduleSheetSubtitle => _t(
    'Set medication times so reminders stay consistent.',
    'Atur waktu minum agar pengingat berjalan konsisten.',
  );
  static String get scheduleNameOptional =>
      _t('Schedule Name (Optional)', 'Nama Jadwal (Opsional)');
  static String get repeatPattern => _t('Repeat Pattern', 'Pola Pengulangan');
  static String get daily => _t('Daily', 'Harian');
  static String get weekly => _t('Weekly', 'Mingguan');
  static String get weeklyHint => _t(
    'Schedule repeats every week at the same time.',
    'Jadwal akan berulang setiap minggu di jam yang sama.',
  );
  static String get startDate => _t('Start Date', 'Tanggal Mulai');
  static String get addTime => _t('Add Time', 'Tambah Waktu');
  static String get duplicateTimeWarning => _t(
    'That time already exists in the schedule.',
    'Waktu tersebut sudah ada di jadwal.',
  );
  static String get minimumOneTimeWarning => _t(
    'Add at least 1 medication time.',
    'Tambahkan minimal 1 waktu minum obat.',
  );
  static String get saveScheduleFailed => _t(
    'Failed to save schedule. Please try again.',
    'Gagal menyimpan jadwal. Silakan coba lagi.',
  );

  // Reminder module
  static String get reminderHourPrefix => _t('At', 'Jam');
  static String get reminderEdit => _t('Edit', 'Edit');
  static String get reminderDeactivate => _t('Disable', 'Nonaktifkan');
  static String get reminderDelete => _t('Delete', 'Hapus');
  static String get disableReminderTitle =>
      _t('Disable Reminder?', 'Nonaktifkan Reminder?');
  static String get deleteReminderTitle =>
      _t('Delete Reminder?', 'Hapus Reminder?');
  static String get reminderFormEditTitle =>
      _t('Edit Reminder', 'Edit Reminder');
  static String get reminderFormAddTitle =>
      _t('Add Reminder', 'Tambah Reminder');
  static String get reminderFormSubtitle => _t(
    'Set type, time, and start date to keep reminders tidy.',
    'Atur jenis, waktu, dan tanggal mulai agar pengingat lebih rapi.',
  );
  static String get customNameOptional =>
      _t('Custom Name (Optional)', 'Nama Kustom (Opsional)');
  static String get saveChanges => _t('Save Changes', 'Simpan Perubahan');

  // Help & support
  static String get helpSupportTitle =>
      _t('Help & Support', 'Bantuan & Dukungan');
  static String get helpIntro =>
      _t('Hi! How can we help you?', 'Hai! Bagaimana kami bisa membantu?');
  static String get popularTopics => _t('POPULAR TOPICS', 'TOPIK POPULER');
  static String get faqTitle =>
      _t('FREQUENTLY ASKED QUESTIONS', 'PERTANYAAN UMUM');
  static String get stillNeedHelp =>
      _t('NEED MORE HELP?', 'MASIH BUTUH BANTUAN?');
  static String get sendEmail => _t('Send Email', 'Kirim Email');
  static String get reportBug => _t('Report Bug', 'Laporkan Bug');
  static String get bugReportSubtitle =>
      _t('Help us fix issues quickly', 'Bantu kami memperbaiki masalah');
  static String get reportBugTitle => _t('Report Bug', 'Laporkan Bug');
  static String get reportBugHint => _t(
    'Describe the issue briefly so our team can follow up faster.',
    'Ceritakan masalah secara ringkas agar tim kami bisa menindaklanjuti lebih cepat.',
  );
  static String get bugDetail => _t('Bug details', 'Detail bug');
  static String get bugDetailExample => _t(
    'Example: When tapping Save in Schedule, the app closes unexpectedly.',
    'Contoh: Saat menekan tombol Simpan di Jadwal, aplikasi tertutup sendiri.',
  );
  static String get submitReport => _t('Submit Report', 'Kirim Laporan');
  static String get bugDetailRequired =>
      _t('Bug detail is required', 'Detail bug wajib diisi');
  static String get bugDetailTooShort =>
      _t('Bug detail is too short', 'Detail bug terlalu singkat');
  static String get openEmailAppFailed => _t(
    'Failed to open email app. Please try again.',
    'Gagal membuka aplikasi email. Silakan coba lagi.',
  );

  // Onboarding
  static String get startNow => _t('Start Now', 'Mulai Sekarang');
  static String get onboardingMedicationTitle =>
      _t('Automatic Medication Reminders', 'Pengingat Obat Otomatis');
  static String get onboardingMedicationDescription => _t(
    'Set medication schedules and get timely notifications. No more missed doses.',
    'Atur jadwal minum obat dan dapatkan notifikasi tepat waktu. Tidak ada lagi dosis yang terlewat.',
  );
  static String get onboardingHealthTitle =>
      _t('Track Your Health', 'Pantau Kesehatan Anda');
  static String get onboardingHealthDescription => _t(
    'Manage medication schedules and health notes in one practical app.',
    'Kelola jadwal obat dan catatan kesehatan dalam satu aplikasi praktis.',
  );
  static String get onboardingReportTitle =>
      _t('Complete Reports & History', 'Laporan & Riwayat Lengkap');
  static String get onboardingReportDescription => _t(
    'See adherence statistics, monitor medication history, and export health reports anytime.',
    'Lihat statistik kepatuhan, pantau riwayat konsumsi obat, dan ekspor laporan kesehatan kapan saja.',
  );

  // Schedule tabs
  static String get scheduleTabMedicine => _t('Medication', 'Obat');
  static String get scheduleTabMeasurement => _t('Measurement', 'Pengukuran');
  static String get scheduleTabActivity => _t('Activity', 'Aktivitas');

  // Reports
  static String get saveAsPdf => _t('Save as PDF', 'Simpan sebagai PDF');
  static String get userFallback => _t('User', 'Pengguna');
  static String get exportPdfFailed => _t(
    'Failed to export PDF. Please try again.',
    'Gagal mengekspor PDF. Silakan coba lagi.',
  );
  static String get dailyLabel => _t('Daily', 'Harian');
  static String get weeklyLabel => _t('Weekly', 'Mingguan');
  static String get monthlyLabel => _t('Monthly', 'Bulanan');
  static String get noReportDataForPeriod =>
      _t('No data for this period yet', 'Belum ada data untuk periode ini');
  static String get reportEmptySubtitle => _t(
    'Start logging health tasks\nto see your reports.',
    'Mulai catat tugas kesehatan\nuntuk melihat laporan Anda.',
  );
  static String get overallAdherence =>
      _t('Overall Adherence', 'Kepatuhan Keseluruhan');
  static String get adherenceLabel => _t('adherence', 'kepatuhan');
  static String get skippedLabel => _t('Skipped', 'Lewati');
  static String get missedLabel => _t('Missed', 'Terlewat');
  static String get medicineLabel => _t('Medication', 'Obat');
  static String get measurementLabel => _t('Measurement', 'Pengukuran');
  static String get physicalActivityLabel =>
      _t('Physical Activity', 'Aktivitas Fisik');
  static String get reportLoadFailed => _t(
    'Failed to load report. Please try again.',
    'Gagal memuat laporan. Silakan coba lagi.',
  );

  // Notification settings
  static String get remindersSection => _t('REMINDERS', 'PENGINGAT');
  static String get alertsSection => _t('ALERTS', 'PERINGATAN');
  static String get reportsSection => _t('REPORTS', 'LAPORAN');
  static String get medicineReminderTitle =>
      _t('Medication Reminder', 'Pengingat Obat');
  static String get medicineReminderSubtitle => _t(
    'Notification for medication schedule',
    'Notifikasi jadwal minum obat',
  );
  static String get measurementReminderTitle =>
      _t('Measurement Reminder', 'Pengingat Pengukuran');
  static String get measurementReminderSubtitle => _t(
    'Notification for health measurement schedule',
    'Notifikasi jadwal pengukuran kesehatan',
  );
  static String get activityReminderTitle =>
      _t('Activity Reminder', 'Pengingat Aktivitas');
  static String get activityReminderSubtitle => _t(
    'Notification for physical activity schedule',
    'Notifikasi jadwal aktivitas fisik',
  );
  static String get alarmToneLabel => _t('Alarm Tone', 'Nada Alarm');
  static String get alarmToneSubtitle => _t(
    'Select ringtone for this reminder type',
    'Pilih nada dering untuk tipe pengingat ini',
  );
  static String get alarmToneUpdated =>
      _t('Alarm tone updated successfully.', 'Nada alarm berhasil diperbarui.');
  static String get ringtoneCc0ChimeNotification =>
      _t('Wake Pulse', 'Pulse Bangun');
  static String get ringtoneCc0PhoneChime => _t('Wake Pulse', 'Pulse Bangun');
  static String get ringtoneCc0SoftBell => _t('Wake Pulse', 'Pulse Bangun');
  static String get ringtoneMedsyncClassic => _t('Wake Pulse', 'Pulse Bangun');
  static String get ringtoneMedsyncAlarmPulse =>
      _t('Wake Pulse', 'Pulse Bangun');
  static String get ringtoneMedsyncAlarmSiren =>
      _t('Warning Beep', 'Beep Peringatan');
  static String get ringtoneMedsyncAlarmBell => _t('Rapid Bell', 'Bel Cepat');
  static String get ringtoneSystemDefault =>
      _t('System Default', 'Default Sistem');
  static String get lowStockAlertTitle =>
      _t('Low Stock Alert', 'Peringatan Stok Rendah');
  static String get lowStockAlertSubtitle => _t(
    'Notification when medication stock is running low',
    'Notifikasi saat stok obat hampir habis',
  );
  static String get streakNotificationTitle =>
      _t('Streak Notification', 'Notifikasi Streak');
  static String get streakNotificationSubtitle => _t(
    'Notification for streak achievements',
    'Pemberitahuan pencapaian streak',
  );
  static String get dailySummaryTitle =>
      _t('Daily Summary', 'Ringkasan Harian');
  static String get dailySummarySubtitle => _t(
    'Daily progress report every night',
    'Laporan progress harian setiap malam',
  );

  // Notification screen
  static String get notificationsLoadFailed => _t(
    'Failed to load notifications. Please try again.',
    'Gagal memuat notifikasi. Silakan coba lagi.',
  );
  static String get deleteNotificationTitle =>
      _t('Delete Notification?', 'Hapus Notifikasi?');
  static String get deleteNotificationMessage => _t(
    'This notification will be permanently removed from your history.',
    'Notifikasi ini akan dihapus permanen dari riwayat Anda.',
  );
  static String get notificationDeleted =>
      _t('Notification deleted.', 'Notifikasi dihapus.');

  // Appearance
  static String get themeSectionTitle => _t('THEME', 'TEMA');
  static String get languageSectionTitle => _t('LANGUAGE', 'BAHASA');
  static String get followSystem => _t('Follow System', 'Ikuti Sistem');
  static String get followSystemSubtitle => _t(
    'Automatically follow device settings',
    'Otomatis sesuai pengaturan perangkat',
  );
  static String get lightMode => _t('Light', 'Terang');
  static String get darkMode => _t('Dark', 'Gelap');
  static String get defaultLabel => _t('Default', 'Default');
  static String get indonesianLanguage =>
      _t('Bahasa Indonesia', 'Bahasa Indonesia');
  static String get indonesianLabel => _t('Indonesia', 'Indonesia');
  static String get settingsSaveFailed => _t(
    'Failed to save settings. Please try again.',
    'Gagal menyimpan pengaturan. Silakan coba lagi.',
  );
  static String get languageChangedToIndonesian => _t(
    'Language changed to Indonesian successfully.',
    'Bahasa berhasil diubah ke Bahasa Indonesia.',
  );
  static String get languageChangedToEnglish => _t(
    'Language changed to English successfully.',
    'Bahasa berhasil diubah ke Bahasa Inggris.',
  );
}
