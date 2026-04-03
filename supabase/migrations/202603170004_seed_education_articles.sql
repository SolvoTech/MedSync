-- Seed 10 education articles.
-- This seeder is idempotent and safe to run multiple times.
-- It requires at least one row in public.profiles to assign author_id.
-- Cover images are sourced from internet search results (Openverse, CC0).

with selected_author as (
  select p.id
  from public.profiles p
  order by
    case when p.role = 'admin' then 0 else 1 end,
    p.created_at asc
  limit 1
),
seed_articles as (
  select *
  from (
    values
      (
        'tips-konsumsi-obat-aman-lansia',
        'Tips Konsumsi Obat yang Aman untuk Lansia',
        'Langkah praktis agar konsumsi obat tetap aman, teratur, dan minim efek samping pada usia lanjut.',
        'Konsumsi obat pada lansia perlu perhatian khusus karena perubahan metabolisme tubuh dapat memengaruhi respons obat. Gunakan kotak obat harian, catat jam minum, dan pastikan dosis sesuai resep dokter. Hindari menggandakan dosis saat lupa minum obat. Perhatikan juga tanda efek samping seperti pusing, mual, atau mengantuk berlebihan. Jika ada keluhan, konsultasikan segera ke tenaga kesehatan.',
        'Obat',
        'https://cdn.stocksnap.io/img-thumbs/960w/PMZZ7WLOAJ.jpg',
        1
      ),
      (
        'cara-mengelola-jadwal-obat-harian',
        'Cara Mengelola Jadwal Obat Harian',
        'Panduan menyusun jadwal obat yang konsisten agar kepatuhan terapi meningkat.',
        'Buat jadwal obat berdasarkan jam aktivitas harian Anda, misalnya setelah sarapan, siang, dan malam. Gunakan pengingat di aplikasi agar tidak terlewat. Simpan obat di tempat yang mudah dijangkau namun aman dari anak-anak. Evaluasi jadwal setiap minggu untuk menyesuaikan perubahan rutinitas. Konsistensi jadwal dapat membantu terapi bekerja lebih optimal.',
        'Manajemen Kesehatan',
        'https://cdn.stocksnap.io/img-thumbs/960w/TPI078T0IS.jpg',
        2
      ),
      (
        'panduan-monitoring-tekanan-darah-di-rumah',
        'Panduan Monitoring Tekanan Darah di Rumah',
        'Cara pengukuran yang benar agar hasil tekanan darah lebih akurat dan dapat dipantau dari waktu ke waktu.',
        'Ukur tekanan darah pada waktu yang sama setiap hari, misalnya pagi dan malam. Duduk tenang selama 5 menit sebelum pengukuran, hindari kafein dan rokok minimal 30 menit sebelumnya. Gunakan manset dengan ukuran sesuai lengan. Catat hasil sistolik dan diastolik untuk dipantau trennya. Jika hasil berulang kali tinggi, konsultasikan ke dokter untuk evaluasi lanjutan.',
        'Pengukuran',
        'https://upload.wikimedia.org/wikipedia/commons/c/c6/Blood_pressure_monitoring.jpg',
        3
      ),
      (
        'memahami-kadar-gula-darah-dan-targetnya',
        'Memahami Kadar Gula Darah dan Targetnya',
        'Ringkasan sederhana tentang target gula darah harian dan kapan perlu waspada.',
        'Pemantauan gula darah membantu Anda memahami dampak makanan, aktivitas, dan obat terhadap tubuh. Catat nilai gula darah puasa dan setelah makan sesuai arahan dokter. Kenali gejala hipoglikemia seperti gemetar, keringat dingin, atau lemas. Jaga pola makan teratur dan jangan melewatkan waktu makan jika menggunakan obat tertentu. Data yang konsisten memudahkan dokter menyesuaikan terapi.',
        'Diabetes',
        'https://upload.wikimedia.org/wikipedia/commons/f/f7/Testing_Blood_Sugar_Levels.jpg',
        4
      ),
      (
        'aktivitas-fisik-ringan-untuk-pemula',
        'Aktivitas Fisik Ringan untuk Pemula',
        'Contoh aktivitas sederhana yang aman dilakukan rutin untuk meningkatkan kebugaran.',
        'Aktivitas ringan seperti jalan kaki 20-30 menit, peregangan, atau senam ringan dapat dilakukan secara bertahap. Mulai dari durasi pendek lalu tingkatkan perlahan sesuai kemampuan. Gunakan alas kaki yang nyaman untuk mencegah cedera. Lakukan pemanasan dan pendinginan agar otot lebih siap. Konsistensi aktivitas membantu menjaga tekanan darah, gula darah, dan kualitas tidur.',
        'Aktivitas Fisik',
        'https://upload.wikimedia.org/wikipedia/commons/d/d4/Isometric_walking_exercises.jpg',
        5
      ),
      (
        'pola-makan-seimbang-untuk-kesehatan-jantung',
        'Pola Makan Seimbang untuk Kesehatan Jantung',
        'Prinsip makan seimbang untuk mendukung kesehatan jantung dalam jangka panjang.',
        'Pilih makanan tinggi serat seperti sayur, buah, dan biji-bijian utuh. Batasi konsumsi garam, gula tambahan, serta lemak jenuh dari makanan olahan. Utamakan metode memasak kukus, rebus, atau panggang dibanding goreng. Atur porsi makan agar tidak berlebihan dan hindari makan terlalu larut malam. Kebiasaan makan seimbang membantu menurunkan risiko penyakit kardiovaskular.',
        'Nutrisi',
        'https://upload.wikimedia.org/wikipedia/commons/f/f1/Food-healthy-meal-morning_%2824325073315%29.jpg',
        6
      ),
      (
        'pencegahan-dehidrasi-dan-cukup-minum',
        'Pencegahan Dehidrasi dan Cukup Minum',
        'Strategi menjaga hidrasi tubuh agar fungsi organ tetap optimal sepanjang hari.',
        'Dehidrasi dapat menurunkan konsentrasi, memicu lemas, dan memperburuk kondisi kesehatan tertentu. Biasakan minum sedikit demi sedikit namun sering, bukan menunggu haus. Pantau warna urin sebagai indikator sederhana hidrasi. Saat cuaca panas atau aktivitas meningkat, kebutuhan cairan juga bertambah. Konsultasikan batas asupan cairan jika Anda memiliki penyakit ginjal atau jantung.',
        'Gaya Hidup',
        'https://live.staticflickr.com/65535/51487313271_2b953bb996_b.jpg',
        7
      ),
      (
        'pentingnya-tidur-berkualitas-untuk-pemulihan',
        'Pentingnya Tidur Berkualitas untuk Pemulihan',
        'Mengapa tidur yang cukup berperan besar dalam pemulihan dan kesehatan harian.',
        'Tidur berkualitas membantu pemulihan fisik, menjaga mood, dan menstabilkan hormon. Upayakan jam tidur dan bangun yang konsisten setiap hari. Kurangi paparan layar ponsel setidaknya 30 menit sebelum tidur. Ciptakan suasana kamar yang tenang dan gelap agar tidur lebih nyenyak. Jika sulit tidur berkepanjangan, pertimbangkan konsultasi medis.',
        'Istirahat',
        'https://live.staticflickr.com/1606/25466556975_90e4b49b98_b.jpg',
        8
      ),
      (
        'mengenali-interaksi-obat-dan-makanan',
        'Mengenali Interaksi Obat dan Makanan',
        'Hal penting yang perlu diperhatikan saat mengonsumsi obat bersamaan dengan makanan tertentu.',
        'Beberapa obat dapat berinteraksi dengan makanan atau minuman tertentu, misalnya susu, kafein, atau grapefruit. Selalu baca petunjuk konsumsi apakah obat diminum sebelum atau sesudah makan. Jangan mencampur suplemen dan obat tanpa konsultasi, terutama jika memiliki penyakit kronis. Catat reaksi yang muncul setelah kombinasi tertentu untuk bahan diskusi dengan dokter. Pemahaman interaksi membantu terapi lebih aman dan efektif.',
        'Obat',
        'https://images.rawpixel.com/editor_1024/czNmcy1wcml2YXRlL3Jhd3BpeGVsX2ltYWdlcy93ZWJzaXRlX2NvbnRlbnQvbHIvaXMxNzU4Mi1pbWFnZS1rd3Z3c3QxMi5qcGc.jpg',
        9
      ),
      (
        'langkah-awal-menangani-lupa-minum-obat',
        'Langkah Awal Menangani Lupa Minum Obat',
        'Apa yang harus dilakukan saat melewatkan jadwal minum obat agar tetap aman.',
        'Jika terlambat minum obat, segera minum saat ingat selama masih jauh dari dosis berikutnya. Jangan menggandakan dosis kecuali diarahkan tenaga kesehatan. Tandai kejadian lupa di catatan agar bisa dievaluasi polanya. Gunakan alarm berulang dan hubungkan jadwal minum obat dengan rutinitas harian. Bila sering terlewat, diskusikan opsi regimen yang lebih sederhana dengan dokter.',
        'Obat',
        'https://cdn.stocksnap.io/img-thumbs/960w/S5WGVL18A9.jpg',
        10
      )
  ) as t(slug, title, summary, content, category, cover_url, order_no)
)
insert into public.education_articles (
  author_id,
  title,
  slug,
  summary,
  content,
  cover_url,
  category,
  status,
  published_at
)
select
  sa.id,
  s.title,
  s.slug,
  s.summary,
  s.content,
  s.cover_url,
  s.category,
  'published',
  now() - ((11 - s.order_no) * interval '1 day')
from selected_author sa
join seed_articles s on true
where sa.id is not null
on conflict (slug)
do update set
  author_id = excluded.author_id,
  title = excluded.title,
  summary = excluded.summary,
  content = excluded.content,
  cover_url = excluded.cover_url,
  category = excluded.category,
  status = excluded.status,
  published_at = excluded.published_at,
  updated_at = now();
