import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService {
  // ── حفظ آخر موقع ──────────────────────────────
  static Future<void> saveLastPosition(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_surah', surahNumber);
    await prefs.setInt('last_ayah', ayahNumber);
  }

  static Future<Map<String, int>> getLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'surah': prefs.getInt('last_surah') ?? 1,
      'ayah': prefs.getInt('last_ayah') ?? 1,
    };
  }

  // ── الإشارات المرجعية ──────────────────────────
  static Future<void> addBookmark(
    int surahNumber,
    int ayahNumber,
    String ayahText,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
    final entry = '$surahNumber:$ayahNumber:$ayahText';
    if (!bookmarks.contains(entry)) {
      bookmarks.add(entry);
      await prefs.setStringList('bookmarks', bookmarks);
    }
  }

  static Future<void> removeBookmark(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
    bookmarks.removeWhere((e) => e.startsWith('$surahNumber:$ayahNumber:'));
    await prefs.setStringList('bookmarks', bookmarks);
  }

  static Future<bool> isBookmarked(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarks = prefs.getStringList('bookmarks') ?? [];
    return bookmarks.any((e) => e.startsWith('$surahNumber:$ayahNumber:'));
  }

  // ── الملاحظات ──────────────────────────────────
  static Future<void> saveNote(
    int surahNumber,
    int ayahNumber,
    String note,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('note_${surahNumber}_$ayahNumber', note);
  }

  static Future<String?> getNote(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('note_${surahNumber}_$ayahNumber');
  }

  static Future<void> deleteNote(int surahNumber, int ayahNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('note_${surahNumber}_$ayahNumber');
  }

  static Future<List<String>> getAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('bookmarks') ?? [];
  }

  static Future<void> clearAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmarks');
  }
}
