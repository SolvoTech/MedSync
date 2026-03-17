String measurementTypeLabel(String value) {
  switch (value) {
    case 'blood_pressure':
      return 'Tekanan Darah';
    case 'blood_sugar':
      return 'Gula Darah';
    case 'heart_rate':
      return 'Detak Jantung';
    case 'weight':
      return 'Berat Badan';
    case 'oxygen_saturation':
      return 'Saturasi Oksigen';
    case 'temperature':
      return 'Suhu Tubuh';
    default:
      return value;
  }
}

String activityTypeLabel(String value) {
  switch (value) {
    case 'walking':
      return 'Jalan Kaki';
    case 'jogging':
      return 'Jogging';
    case 'cycling':
      return 'Bersepeda';
    case 'stretching':
      return 'Peregangan';
    case 'yoga':
      return 'Yoga';
    case 'other':
      return 'Lainnya';
    default:
      return value;
  }
}
