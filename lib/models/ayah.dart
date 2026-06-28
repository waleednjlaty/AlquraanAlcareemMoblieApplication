class Ayah {
  final int number;
  final String text;
  final int numberInSurah;

  const Ayah({
    required this.number,
    required this.text,
    required this.numberInSurah,
  });

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
    number: j['number'],
    text: j['text'],
    numberInSurah: j['numberInSurah'],
  );
}
