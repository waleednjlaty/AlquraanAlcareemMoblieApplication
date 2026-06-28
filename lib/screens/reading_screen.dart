import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../providers/quran_provider.dart';
import '../models/surah.dart';
import '../services/audio_service.dart';
import '../services/bookmark_service.dart';

class ReadingScreen extends StatefulWidget {
  final int surahNumber;
  final int scrollToAyah;

  const ReadingScreen({
    super.key,
    required this.surahNumber,
    this.scrollToAyah = 1,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with WidgetsBindingObserver {
  final AudioService _audio = AudioService();
  final ScrollController _scrollController = ScrollController();

  int? _highlightedAyah;
  int? _playingAyah;
  bool _isPlaying = false;
  double fonta = 20;
  List<GlobalKey> _ayahKeys = [];
  int? _previousAyahCount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    fonta = context.read<QuranProvider>().defaultFontSize;

    Future.microtask(() async {
      await context.read<QuranProvider>().loadAyahs(widget.surahNumber);
      if (widget.scrollToAyah > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToAyah(widget.scrollToAyah);
        });
        if (mounted) setState(() => _highlightedAyah = widget.scrollToAyah);
      }
    });

    _audio.currentAyahStream.listen((ayah) {
      if (mounted) {
        setState(() {
          _playingAyah = ayah;
          _highlightedAyah = ayah;
        });
        _scrollToAyah(ayah);
        final p = context.read<QuranProvider>();
        p.setLastAyah(ayah);
        BookmarkService.saveLastPosition(widget.surahNumber, ayah);
      }
    });

    _audio.onPlaybackComplete.listen((_) {
      if (_playingAyah == null || !mounted) return;
      final provider = context.read<QuranProvider>();
      if (!provider.autoPlay) {
        setState(() => _playingAyah = null);
        _audio.stop();
        return;
      }
      final nextAyah = _playingAyah! + 1;
      if (nextAyah <= provider.ayahs.length) {
        _audio.playAyah(widget.surahNumber, nextAyah,
            reciterKey: provider.reciterKey,
            totalAyahs: provider.ayahs.length);
      } else {
        setState(() => _playingAyah = null);
        _audio.stop();
      }
    });

    _audio.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
  }

  void _saveCurrentPosition() {
    final ayah = _highlightedAyah ?? 1;
    context.read<QuranProvider>().setLastAyah(ayah);
    BookmarkService.saveLastPosition(widget.surahNumber, ayah);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _saveCurrentPosition();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveCurrentPosition();
    _audio.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToAyah(int ayahNumber, {int retries = 3}) {
    final index = ayahNumber - 1;
    if (index < 0 || index >= _ayahKeys.length) return;
    final ctx = _ayahKeys[index].currentContext;
    if (ctx == null) {
      if (retries > 0) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToAyah(ayahNumber, retries: retries - 1);
        });
      }
      return;
    }
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  void _showOptionsMenu() {
    final provider = context.read<QuranProvider>();
    final totalSurahs = provider.surahs.length;
    bool isDark = provider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: AC.surface(ctx),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AC.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── حجم الخط ──────────────────────
              Row(
                children: [
                  Icon(Icons.format_size, color: AC.gold(context), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'حجم الخط',
                    style: TextStyle(
                      color: AC.goldLight(context),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      if (fonta > 14) {
                        setModalState(() {});
                        setState(() => fonta -= 2);
                        context.read<QuranProvider>().setFontSize(fonta);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: AC.border(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.remove,
                        color: AC.gold(context),
                        size: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '${fonta.toInt()}',
                      style: TextStyle(
                        color: AC.gold(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (fonta < 32) {
                        setModalState(() {});
                        setState(() => fonta += 2);
                        context.read<QuranProvider>().setFontSize(fonta);
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(color: AC.border(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: AC.gold(context), size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AC.border(context), height: 1),
              const SizedBox(height: 16),

              // ── الثيم ──────────────────────────
              Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: AC.gold(context),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isDark ? 'وضع الليل' : 'وضع النهار',
                    style: TextStyle(
                      color: AC.goldLight(context),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: isDark,
                    onChanged: (val) {
                      context.read<QuranProvider>().toggleTheme();
                      isDark = !isDark;
                      setModalState(() {});
                    },
                    activeTrackColor: AC.gold(context).withValues(alpha: 0.4),
                    activeThumbColor: AC.gold(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AC.border(context), height: 1),
              const SizedBox(height: 16),

              // ── الانتقال للسورة ────────────────
              Row(
                children: [
                  Icon(Icons.swap_horiz, color: AC.gold(context), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'الانتقال للسورة',
                    style: TextStyle(
                      color: AC.goldLight(context),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.surahNumber > 1
                        ? () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReadingScreen(
                                  surahNumber: widget.surahNumber - 1,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.surahNumber > 1
                              ? AC.borderMid(context)
                              : AC.border(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'السابقة',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.surahNumber > 1
                              ? AC.gold(context)
                              : AC.text(context),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: widget.surahNumber < totalSurahs
                        ? () {
                            Navigator.pop(ctx);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReadingScreen(
                                  surahNumber: widget.surahNumber + 1,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.surahNumber < totalSurahs
                            ? AC.gold(context).withValues(alpha: 0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.surahNumber < totalSurahs
                              ? AC.borderMid(context)
                              : AC.border(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'التالية',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.surahNumber < totalSurahs
                              ? AC.gold(context)
                              : AC.text(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: AC.border(context), height: 1),
              const SizedBox(height: 16),

              // ── مشاركة السورة ──────────────────
              GestureDetector(
                onTap: () async {
                  final surah = provider.surahs[widget.surahNumber - 1];
                  await Clipboard.setData(
                    ClipboardData(
                      text:
                          'اقرأ سورة ${surah.nameArabic} في تطبيق القرآن الكريم',
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    _showSnack('تم نسخ نص المشاركة');
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AC.border(context)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.share_outlined,
                        color: AC.gold(context),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'مشاركة السورة',
                        style: TextStyle(
                          color: AC.gold(context),
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _showExitDialog() async {
    await _audio.stop();
    if (mounted) setState(() => _playingAyah = null);

    if (!mounted) return;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AC.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.exit_to_app, color: AC.gold(context), size: 40),
              const SizedBox(height: 16),
              Text(
                'الخروج',
                style: TextStyle(
                  color: AC.goldLight(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'هل تريد الخروج من هذه السورة؟',
                textAlign: TextAlign.center,
                style: TextStyle(color: AC.text(context), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, 'no'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AC.gold(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'لا',
                        style: TextStyle(color: AC.gold(context)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, 'yes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AC.gold(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'نعم',
                        style: TextStyle(color: AC.bg(context)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == 'yes' && mounted) {
      final provider = context.read<QuranProvider>();
      final ayah = _highlightedAyah ?? (provider.lastAyahNumber > 1 ? provider.lastAyahNumber : 1);
      BookmarkService.saveLastPosition(widget.surahNumber, ayah);
      provider.setLastAyah(ayah);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final surah = provider.surahs.isNotEmpty
        ? provider.surahs[widget.surahNumber - 1]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, surah),
            Expanded(
              child: provider.loading
                  ? Center(
                      child: CircularProgressIndicator(color: AC.gold(context)),
                    )
                  : _buildPageFrame(provider, surah),
            ),
            if (_playingAyah != null) _buildAudioBar(provider),
            _buildBottomControls(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Surah? surah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showExitDialog,
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
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surah?.nameArabic ?? '',
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    color: AC.goldLight(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  surah != null
                      ? '${surah.nameEnglish} • ${surah.revelationType == "Meccan" ? "مكية" : "مدنية"}'
                      : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: AC.text(context),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showOptionsMenu,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(color: AC.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.more_horiz, color: AC.gold(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageFrame(QuranProvider provider, Surah? surah) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: AC.surface(context),
        border: Border.all(color: AC.border(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            ..._buildCorners(),
            ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children: [
                _buildSurahHeader(surah),
                const SizedBox(height: 16),
                _buildBasmala(),
                const SizedBox(height: 16),
                ..._buildAyahs(provider),
                const SizedBox(height: 8),
                _buildPageNumber(provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurahHeader(Surah? surah) {
    return Column(
      children: [
        _goldDivider(),
        const SizedBox(height: 10),
        Text(
          surah?.nameArabic ?? '',
          style: GoogleFonts.amiri(
            fontSize: 26,
            color: AC.gold(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _goldDivider(),
      ],
    );
  }

  Widget _buildBasmala() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textAlign: TextAlign.center,
        style: GoogleFonts.amiri(
          fontSize: 18,
          color: AC.text(context),
          height: 1.8,
        ),
      ),
    );
  }

  List<Widget> _buildAyahs(QuranProvider provider) {
    if (provider.ayahs.isEmpty) return [];

    if (provider.ayahs.length != _previousAyahCount) {
      _ayahKeys = List.generate(
        provider.ayahs.length,
        (_) => GlobalKey(),
      );
      _previousAyahCount = provider.ayahs.length;
    }

    return List.generate(provider.ayahs.length, (index) {
      final ayah = provider.ayahs[index];
      String text = ayah.text;
      if (widget.surahNumber != 1 && ayah.numberInSurah == 1) {
        final bsm = '\u0628\u0650\u0633\u0652\u0645\u0650 \u0671\u0644\u0644\u0651\u064e\u0647\u0650 \u0671\u0644\u0631\u0651\u064e\u062d\u0652\u0645\u064e\u0670\u0646\u0650 \u0671\u0644\u0631\u0651\u064e\u062d\u0650\u064a\u0645\u0650';
        int idx = text.indexOf(bsm);
        if (idx != -1) {
          text = text.substring(idx + bsm.length).trim();
        }
      }

      final isHighlighted = _highlightedAyah == ayah.numberInSurah;
      final isPlaying = _playingAyah == ayah.numberInSurah;

      return Container(
        key: _ayahKeys[index],
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AC.gold(context).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$text ',
                style: GoogleFonts.amiri(
                  fontSize: fonta,
                  height: 2.2,
                  color: isPlaying
                      ? AC.gold(context)
                      : AC.goldLight(context).withValues(alpha: 0.9),
                ),
                recognizer: LongPressGestureRecognizer()
                  ..onLongPress = () => _toggleAyahAudio(ayah.numberInSurah),
              ),
              TextSpan(
                text: '﴿${_toArabicNum(ayah.numberInSurah)}﴾ ',
                style: TextStyle(
                  fontSize: fonta * 0.8,
                  height: 2.2,
                  color: isPlaying
                      ? AC.gold(context)
                      : AC.gold(context).withValues(alpha: 0.6),
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    setState(() {
                      _highlightedAyah = _highlightedAyah == ayah.numberInSurah
                          ? null
                          : ayah.numberInSurah;
                    });
                    _scrollToAyah(ayah.numberInSurah);
                    provider.setLastAyah(ayah.numberInSurah);
                    BookmarkService.saveLastPosition(
                      widget.surahNumber,
                      ayah.numberInSurah,
                    );
                  },
              ),
            ],
          ),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
      );
    });
  }

  Widget _buildAudioBar(QuranProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AC.surface(context),
        border: Border.all(color: AC.borderMid(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (_isPlaying) {
                await _audio.pause();
              } else {
                await _audio.resume();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AC.gold(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: AC.bg(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الشيخ ${provider.reciterName}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AC.gold(context),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'الآية ${_toArabicNum(_playingAyah!)} — ${provider.surahs.isNotEmpty ? provider.surahs[widget.surahNumber - 1].nameArabic : ""}',
                  style: TextStyle(fontSize: 10, color: AC.text(context)),
                ),
                const SizedBox(height: 4),
                StreamBuilder<Duration>(
                  stream: _audio.positionStream,
                  builder: (_, posSnap) => StreamBuilder<Duration?>(
                    stream: _audio.durationStream,
                    builder: (_, durSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final dur = durSnap.data ?? Duration.zero;
                      final progress = dur.inMilliseconds > 0
                          ? pos.inMilliseconds / dur.inMilliseconds
                          : 0.0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: AC.bg(context),
                          valueColor: AlwaysStoppedAnimation(AC.gold(context)),
                          minHeight: 3,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              _audio.stop();
              setState(() => _playingAyah = null);
            },
            child: Icon(Icons.close, color: AC.text(context), size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AC.bg(context),
        border: Border(top: BorderSide(color: AC.border(context), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ctrlBtn(Icons.bookmark_border, 'حفظ', onTap: _saveBookmark),
          _ctrlBtn(
            Icons.format_quote,
            'تفسير',
            onTap: _showTafseer,
            active: true,
          ),
          _ctrlBtn(Icons.copy, 'نسخ', onTap: _copyAyah),
          _ctrlBtn(Icons.edit_note, 'ملاحظات', onTap: _showNotes),
        ],
      ),
    );
  }

  Widget _ctrlBtn(
    IconData icon,
    String label, {
    bool active = false,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active
                  ? AC.gold(context).withValues(alpha: 0.12)
                  : AC.surface(context),
              border: Border.all(
                color: active ? AC.borderMid(context) : AC.border(context),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: active ? AC.gold(context) : AC.text(context),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AC.text(context),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBookmark() async {
    if (_highlightedAyah == null) {
      _showSnack('اختر آية أولاً بالضغط على رقمها');
      return;
    }
    final provider = context.read<QuranProvider>();
    final ayah = provider.ayahs.firstWhere(
      (a) => a.numberInSurah == _highlightedAyah,
    );
    final already = await BookmarkService.isBookmarked(
      widget.surahNumber,
      _highlightedAyah!,
    );
    if (already) {
      await BookmarkService.removeBookmark(
        widget.surahNumber,
        _highlightedAyah!,
      );
      _showSnack('تم حذف الإشارة المرجعية');
    } else {
      await BookmarkService.addBookmark(
        widget.surahNumber,
        _highlightedAyah!,
        ayah.text,
      );
      await BookmarkService.saveLastPosition(
        widget.surahNumber,
        _highlightedAyah!,
      );
      _showSnack('تم حفظ الآية ﴿$_highlightedAyah﴾');
    }
  }

  Future<void> _copyAyah() async {
    if (_highlightedAyah == null) {
      _showSnack('اختر آية أولاً بالضغط على رقمها');
      return;
    }
    final provider = context.read<QuranProvider>();
    final ayah = provider.ayahs.firstWhere(
      (a) => a.numberInSurah == _highlightedAyah,
    );
    final surah = provider.surahs[widget.surahNumber - 1];
    await Clipboard.setData(
      ClipboardData(
        text: '${ayah.text}\n﴿${surah.nameArabic} — الآية $_highlightedAyah﴾',
      ),
    );
    _showSnack('تم نسخ الآية ﴿$_highlightedAyah﴾');
  }

  Future<void> _showTafseer() async {
    if (_highlightedAyah == null) {
      _showSnack('اختر آية أولاً بالضغط على رقمها');
      return;
    }
    final provider = context.read<QuranProvider>();
    final ayah = provider.ayahs.firstWhere(
      (a) => a.numberInSurah == _highlightedAyah,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: AC.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => _TafseerSheet(
        surahNumber: widget.surahNumber,
        ayahNumber: _highlightedAyah!,
        ayahText: ayah.text,
      ),
    );
  }

  Future<void> _showNotes() async {
    if (_highlightedAyah == null) {
      _showSnack('اختر آية أولاً بالضغط على رقمها');
      return;
    }
    final existingNote = await BookmarkService.getNote(
      widget.surahNumber,
      _highlightedAyah!,
    );
    final controller = TextEditingController(text: existingNote ?? '');
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AC.surface(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: AC.gold(context), size: 20),
                const SizedBox(width: 8),
                Text(
                  'ملاحظة — الآية $_highlightedAyah',
                  style: TextStyle(
                    color: AC.gold(context),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.amiri(
                color: AC.goldLight(context),
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'اكتب ملاحظتك هنا...',
                hintStyle: GoogleFonts.amiri(
                  color: AC.text(context),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: AC.bg(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AC.border(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AC.gold(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AC.border(context)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (existingNote != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await BookmarkService.deleteNote(
                          widget.surahNumber,
                          _highlightedAyah!,
                        );
                        Navigator.pop(ctx);
                        _showSnack('تم حذف الملاحظة');
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'حذف',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                        await BookmarkService.saveNote(
                          widget.surahNumber,
                          _highlightedAyah!,
                          controller.text.trim(),
                        );
                        Navigator.pop(ctx);
                        _showSnack('تم حفظ الملاحظة');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AC.gold(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text('حفظ', style: TextStyle(color: AC.bg(context))),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.amiri(color: AC.bg(context)),
        ),
        backgroundColor: AC.gold(context),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleAyahAudio(int ayahNumber) async {
    if (_playingAyah == ayahNumber && _isPlaying) {
      await _audio.pause();
      return;
    }
    if (_isPlaying) {
      await _audio.stop();
    }
    if (!mounted) return;
    final provider = context.read<QuranProvider>();
    setState(() => _playingAyah = ayahNumber);
    await _audio.playAyah(widget.surahNumber, ayahNumber,
        reciterKey: provider.reciterKey,
        totalAyahs: provider.ayahs.length,
        batchSize: provider.autoPlay ? 4 : 1);
  }

  List<Widget> _buildCorners() {
    final size = 28.0;
    final color = AC.borderMid(context);
    const w = 1.0;
    return [
      Positioned(
        top: 10,
        right: 10,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              top: true,
              right: true,
              color: color,
              strokeWidth: w,
            ),
          ),
        ),
      ),
      Positioned(
        top: 10,
        left: 10,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              top: true,
              right: false,
              color: color,
              strokeWidth: w,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        right: 10,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              top: false,
              right: true,
              color: color,
              strokeWidth: w,
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        left: 10,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CornerPainter(
              top: false,
              right: false,
              color: color,
              strokeWidth: w,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _goldDivider() {
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

  Widget _buildPageNumber(QuranProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'سورة ${widget.surahNumber} • ${provider.ayahs.length} آية',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          color: AC.goldMuted(context),
          letterSpacing: 2,
        ),
      ),
    );
  }

  String _toArabicNum(int n) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => digits[int.parse(d)]).join();
  }
}

// ── التفسير ────────────────────────────────────────
class _TafseerSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String ayahText;

  const _TafseerSheet({
    required this.surahNumber,
    required this.ayahNumber,
    required this.ayahText,
  });

  @override
  State<_TafseerSheet> createState() => _TafseerSheetState();
}

class _TafseerSheetState extends State<_TafseerSheet> {
  String? _tafseer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTafseer();
  }

  Future<void> _loadTafseer() async {
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://api.alquran.cloud/v1/ayah/${widget.surahNumber}:${widget.ayahNumber}/ar.muyassar',
            ),
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final text = jsonDecode(res.body)['data']['text'] as String;
        setState(() {
          _tafseer = text;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'فشل تحميل التفسير';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تأكد من الاتصال بالإنترنت';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AC.border(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.format_quote, color: AC.gold(context), size: 20),
                const SizedBox(width: 8),
                Text(
                  'تفسير الآية ﴿${widget.ayahNumber}﴾',
                  style: TextStyle(
                    color: AC.gold(context),
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AC.bg(context),
                border: Border.all(color: AC.border(context)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.ayahText,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: AC.goldLight(context),
                  height: 1.8,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'التفسير الميسر',
              style: TextStyle(
                fontSize: 11,
                color: AC.text(context),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AC.gold(context)),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : ListView(
                      controller: controller,
                      children: [
                        Text(
                          _tafseer ?? '',
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.amiri(
                            fontSize: 16,
                            color: AC
                                .goldLight(context)
                                .withValues(alpha: 0.85),
                            height: 2.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── رسام الزوايا ───────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool top, right;
  final Color color;
  final double strokeWidth;

  const _CornerPainter({
    required this.top,
    required this.right,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path();
    if (top && right) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (top && !right) {
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (!top && right) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(0, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
