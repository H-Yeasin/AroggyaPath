class Symptoms {
  final String image;
  final String label;

  Symptoms({
    required this.image,
    required this.label,
  });
}

List<Symptoms> symptoms = [
  Symptoms(
    image: 'assets/doctor-appoinment/breakfast.png',
    label: 'সকালের নাস্তা ছাড়বেন না',
  ),
  Symptoms(
    image: 'assets/doctor-appoinment/tooth.png',
    label: 'ঠিকভাবে দাঁত ব্রাশ করুন',
  ),
  Symptoms(
    image: 'assets/doctor-appoinment/exercise.png',
    label: 'সকালে কিছুক্ষণ স্ট্রেচিং করুন',
  ),
  Symptoms(
    image: 'assets/doctor-appoinment/religion.png',
    label: 'নিজ ধর্মে মনোযোগ দিন',
  ),
  Symptoms(
    image: 'assets/doctor-appoinment/water.png',
    label: 'পর্যাপ্ত পানি গ্রহণ',
  ),
];
