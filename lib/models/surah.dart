class Surah {
  final int number;
  final String nameArabic;
  final String nameEnglish;
  final int numberOfAyahs;
  final String revelationType;

  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameEnglish,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    number: j['number'],
    nameArabic: j['name'],
    nameEnglish: j['englishName'],
    numberOfAyahs: j['numberOfAyahs'],
    revelationType: j['revelationType'],
  );
}
