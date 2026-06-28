import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import 'reading_screen.dart';
import 'package:fuzzy/fuzzy.dart';
import '../core/juz_data.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final TextEditingController _search = TextEditingController();
  List<Surah> _filtered = [];
  int? _selectedJuz;

  String _removeArabicDiacritics(String text) =>
      text.replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F]'), '');

  void _applyFilter(List<Surah> surahs, String q) {
    List<Surah> base = surahs;
    if (_selectedJuz != null) {
      final juzNums = juzSurahs[_selectedJuz!] ?? [];
      base = surahs.where((s) => juzNums.contains(s.number)).toList();
    }
    if (q.isEmpty) {
      _filtered = base;
    } else {
      final fuzzy = Fuzzy<Surah>(
        base,
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'nameArabic',
              getter: (s) => _removeArabicDiacritics(s.nameArabic),
              weight: 0.6,
            ),
            WeightedKey(
              name: 'nameEnglish',
              getter: (s) => s.nameEnglish,
              weight: 0.3,
            ),
            WeightedKey(
              name: 'number',
              getter: (s) => '${s.number}',
              weight: 0.1,
            ),
          ],
          threshold: 0.8,
          distance: 200,
          shouldSort: true,
        ),
      );
      _filtered = fuzzy.search(q).map((r) => r.item).toList();
    }
  }

  @override
  void initState() {
    super.initState();
    final surahs = context.read<QuranProvider>().surahs;
    _filtered = surahs;
    _search.addListener(() {
      final q = _removeArabicDiacritics(_search.text.trim());
      setState(() => _applyFilter(surahs, q));
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            _buildSearchBar(context),
            _buildJuzRow(context),
            Expanded(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  // ── الشريط العلوي ──────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: AC.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: AC.gold(context),
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'السور',
            style: GoogleFonts.amiri(
              fontSize: 22,
              color: AC.gold(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '١١٤ سورة',
            style: TextStyle(
              fontSize: 11,
              color: AC.text(context),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ── شريط البحث ─────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AC.surface(context),
        border: Border.all(color: AC.border(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: AC.text(context), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _search,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                color: AC.goldLight(context),
                fontSize: 16,
              ),
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة...',
                hintStyle: GoogleFonts.amiri(
                  color: AC.text(context),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            GestureDetector(
              onTap: () => _search.clear(),
              child: Icon(Icons.close, color: AC.text(context), size: 16),
            ),
        ],
      ),
    );
  }

  // ── أجزاء القرآن ───────────────────────────────
  Widget _buildJuzRow(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16, left: 8),
        itemCount: 31,
        itemBuilder: (_, i) {
          final isAll = i == 0;
          final juzNum = i;
          final isSelected = isAll
              ? _selectedJuz == null
              : _selectedJuz == juzNum;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedJuz = isAll ? null : juzNum;
                _applyFilter(
                  context.read<QuranProvider>().surahs,
                  _removeArabicDiacritics(_search.text.trim()),
                );
              });
            },
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AC.gold(context).withValues(alpha: 0.15)
                    : AC.surface(context),
                border: Border.all(
                  color: isSelected
                      ? AC.borderMid(context)
                      : AC.border(context),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  isAll ? 'الكل' : 'الجزء ${_toArabicNum(juzNum)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? AC.gold(context) : AC.text(context),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── قائمة السور ────────────────────────────────
  Widget _buildList(BuildContext context) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: GoogleFonts.amiri(color: AC.text(context), fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildSurahTile(context, _filtered[i]),
    );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReadingScreen(surahNumber: surah.number),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AC.surface(context),
          border: Border.all(color: AC.border(context)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: AC.borderMid(context)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _toArabicNum(surah.number),
                  style: TextStyle(
                    color: AC.gold(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.nameEnglish,
                    style: TextStyle(
                      fontSize: 11,
                      color: AC.text(context),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${surah.revelationType == "Meccan" ? "مكية" : "مدنية"} • ${surah.numberOfAyahs} آية',
                    style: TextStyle(
                      fontSize: 10,
                      color: AC.goldMuted(context),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              surah.nameArabic,
              style: GoogleFonts.amiri(
                fontSize: 20,
                color: AC.goldLight(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _toArabicNum(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}
