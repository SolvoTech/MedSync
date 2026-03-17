/// Data model for a single onboarding page.
class OnboardingPageModel {
  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final String icon; // emoji or asset path

  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'Pengingat Obat Otomatis',
      description:
          'Atur jadwal minum obat dan dapatkan pengingat tepat waktu. '
          'Tidak ada lagi dosis yang terlewat.',
      icon: 'assets/images/onboarding_1.png',
    ),
    OnboardingPageModel(
      title: 'Pantau Kesehatan Keluarga',
      description:
          'Kelola jadwal obat dan catatan kesehatan untuk '
          'anggota keluarga dalam satu aplikasi.',
      icon: 'assets/images/onboarding_2.png',
    ),
    OnboardingPageModel(
      title: 'Laporan & Riwayat Lengkap',
      description:
          'Lihat statistik kepatuhan, riwayat minum obat, '
          'dan ekspor laporan kapan saja.',
      icon: 'assets/images/onboarding_3.png',
    ),
  ];
}
