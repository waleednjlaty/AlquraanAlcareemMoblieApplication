import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../providers/quran_provider.dart';
import 'surah_list_screen.dart';
import 'reading_screen.dart';
import '../services/bookmark_service.dart';
import '../widgets/bookmarks_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<QuranProvider>();
      if (provider.surahs.isEmpty) {
        await provider.loadSurahs();
      }
      final pos = await BookmarkService.getLastPosition();
      if (mounted) {
        provider.lastSurahNumber = pos['surah']!;
        provider.lastAyahNumber = pos['ayah']!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildTopBar(context),
              const SizedBox(height: 16),
              _buildBasmala(context),
              const SizedBox(height: 16),
              if (provider.loading)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AC.gold(context)),
                )
              else ...[
                _buildLastRead(context, provider),
                const SizedBox(height: 20),
                _buildSectionLabel(context, 'السور المقترحة'),
                const SizedBox(height: 10),
                _buildSurahGrid(context, provider),
                const SizedBox(height: 20),
                _buildAllSurahsBtn(context),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── الشريط العلوي ──────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'القرآن الكريم',
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AC.gold(context),
                letterSpacing: 1,
              ),
            ),
            Text(
              'AL-QURAN AL-KAREEM',
              style: TextStyle(
                fontSize: 10,
                color: AC.text(context),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AC.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () => showBookmarksSheet(context),
                child: Icon(
                  Icons.bookmark_outline,
                  color: AC.gold(context),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AC.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: AC.gold(context),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── البسملة ────────────────────────────────────
  Widget _buildBasmala(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AC.surface(context),
        border: Border.all(color: AC.border(context)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _goldDivider(context),
          const SizedBox(height: 12),
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            style: GoogleFonts.amiri(
              fontSize: 20,
              color: AC.goldLight(context),
              height: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BISMILLAH',
            style: TextStyle(
              fontSize: 10,
              color: AC.goldMuted(context),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── آخر قراءة ──────────────────────────────────
  Widget _buildLastRead(BuildContext context, QuranProvider provider) {
    if (provider.surahs.isEmpty) return const SizedBox();
    final surah = provider.surahs[provider.lastSurahNumber - 1];
    return GestureDetector(
      onTap: () => _openReading(context, provider, surah.number),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AC.surface(context),
          border: Border.all(color: AC.borderMid(context)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AC.borderMid(context)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: AC.gold(context),
                    fontSize: 16,
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
                    'متابعة القراءة',
                    style: TextStyle(
                      fontSize: 10,
                      color: AC.text(context),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    surah.nameArabic,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      color: AC.goldLight(context),
                    ),
                  ),
                  Text(
                    'الآية ${_toArabicNum(provider.lastAyahNumber)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AC.goldMuted(context),
                    ),
                  ),
                  Text(
                    '${surah.nameEnglish} • ${surah.revelationType == "Meccan" ? "مكية" : "مدنية"}',
                    style: TextStyle(fontSize: 11, color: AC.text(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_outline, color: AC.gold(context), size: 32),
          ],
        ),
      ),
    );
  }

  // ── شبكة السور ─────────────────────────────────
  Widget _buildSurahGrid(BuildContext context, QuranProvider provider) {
    final featured = [1, 2, 18, 36, 55, 67];
    final surahs = provider.surahs
        .where((s) => featured.contains(s.number))
        .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: surahs.length,
      itemBuilder: (_, i) => _buildSurahCard(context, provider, surahs[i]),
    );
  }

  Widget _buildSurahCard(BuildContext context, QuranProvider provider, surah) {
    return GestureDetector(
      onTap: () => _openReading(context, provider, surah.number),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AC.surface(context),
          border: Border.all(color: AC.border(context)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: AC.borderMid(context)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${surah.number}',
                  style: TextStyle(color: AC.gold(context), fontSize: 11),
                ),
              ),
            ),
            const Spacer(),
            Text(
              surah.nameArabic,
              style: GoogleFonts.amiri(
                fontSize: 16,
                color: AC.goldLight(context),
              ),
            ),
            Text(
              surah.nameEnglish,
              style: TextStyle(
                fontSize: 10,
                color: AC.text(context),
                letterSpacing: 1,
              ),
            ),
            Text(
              '${surah.numberOfAyahs} آية',
              style: TextStyle(fontSize: 10, color: AC.goldMuted(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ── زر كل السور ────────────────────────────────
  Widget _buildAllSurahsBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SurahListScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AC.borderMid(context)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'عرض جميع السور',
              style: TextStyle(
                color: AC.gold(context),
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_back_ios, color: AC.gold(context), size: 14),
          ],
        ),
      ),
    );
  }

  // ── مساعدات ────────────────────────────────────
  Widget _buildSectionLabel(BuildContext context, String label) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: AC.gold(context),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _goldDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: AC.border(context))),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AC.gold(context),
            shape: BoxShape.rectangle,
            borderRadius: const BorderRadius.all(Radius.circular(1)),
          ),
          transform: Matrix4.rotationZ(0.785),
        ),
        Expanded(child: Container(height: 0.5, color: AC.border(context))),
      ],
    );
  }

  void _openReading(
    BuildContext context,
    QuranProvider provider,
    int surahNumber,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen(
          surahNumber: surahNumber,
          scrollToAyah: surahNumber == provider.lastSurahNumber
              ? provider.lastAyahNumber
              : 1,
        ),
      ),
    );
  }

  String _toArabicNum(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}
