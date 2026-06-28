import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/surah.dart';
import '../models/ayah.dart';

class QuranService {
  static Future<List<Surah>> getSurahs() async {
    final json = await rootBundle.loadString('assets/data/surahs.json');
    final data = jsonDecode(json)['data'] as List;
    return data.map((e) => Surah.fromJson(e)).toList();
  }

  static Future<List<Ayah>> getAyahs(int surahNumber) async {
    final json =
        await rootBundle.loadString('assets/data/ayahs_$surahNumber.json');
    final ayahs = jsonDecode(json)['data']['ayahs'];
    return (ayahs as List).map((e) => Ayah.fromJson(e)).toList();
  }
}
