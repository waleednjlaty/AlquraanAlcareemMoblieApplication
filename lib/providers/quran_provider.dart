import 'package:flutter/material.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../services/quran_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranProvider extends ChangeNotifier {
  List<Surah> surahs = [];
  List<Ayah> ayahs = [];
  bool loading = false;

  int lastSurahNumber = 1;
  int lastAyahNumber = 1;
  double defaultFontSize = 20;
  bool autoPlay = true;
  String reciterKey = 'Alafasy_128kbps';
  String reciterName = 'مشاري العفاسي';

  bool isDarkMode = true;

  Future<void> setFontSize(double size) async {
    defaultFontSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setAutoPlay(bool val) async {
    autoPlay = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoPlay', val);
    notifyListeners();
  }

  Future<void> setReciter(String key, String name) async {
    reciterKey = key;
    reciterName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reciterKey', key);
    await prefs.setString('reciterName', name);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode = prefs.getBool('isDarkMode') ?? true;
    defaultFontSize = prefs.getDouble('fontSize') ?? 20;
    autoPlay = prefs.getBool('autoPlay') ?? true;
    reciterKey =
        prefs.getString('reciterKey') ?? 'Alafasy_128kbps';
    reciterName = prefs.getString('reciterName') ?? 'مشاري العفاسي';
    notifyListeners();
  }

  Future<void> loadSurahs() async {
    loading = true;
    notifyListeners();
    surahs = await QuranService.getSurahs();
    loading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    isDarkMode = !isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    notifyListeners();
  }

  Future<void> loadAyahs(int surahNumber) async {
    loading = true;
    notifyListeners();
    ayahs = await QuranService.getAyahs(surahNumber);
    lastSurahNumber = surahNumber;
    loading = false;
    notifyListeners();
  }

  void setLastAyah(int ayahNumber) {
    lastAyahNumber = ayahNumber;
    notifyListeners();
  }

  Future<void> resetData() async {
    surahs = [];
    ayahs = [];
    surahs = await QuranService.getSurahs();
    notifyListeners();
  }
}
