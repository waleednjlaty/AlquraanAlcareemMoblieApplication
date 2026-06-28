import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../core/theme.dart';
import '../providers/quran_provider.dart';
import '../services/bookmark_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _audioStarted = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final provider = context.read<QuranProvider>();
    await provider.loadSurahs();
    final pos = await BookmarkService.getLastPosition();
    provider.lastSurahNumber = pos['surah']!;
    provider.lastAyahNumber = pos['ayah']!;

    await Future.delayed(const Duration(milliseconds: 300));
    await _playBismillah();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _playBismillah() async {
    if (_audioStarted) return;
    _audioStarted = true;
    try {
      await _player.setAudioSource(
        AudioSource.uri(
          Uri.parse(
            'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
          ),
        ),
      );
      await _player.play();
      await _player.processingStateStream
          .firstWhere((state) => state == ProcessingState.completed);
    } catch (_) {}
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AC.gold(context).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: AC.borderMid(context)),
              ),
              child: Icon(
                Icons.menu_book,
                color: AC.gold(context),
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'القرآن الكريم',
              style: GoogleFonts.amiri(
                fontSize: 30,
                color: AC.gold(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AL-QURAN AL-KAREEM',
              style: TextStyle(
                fontSize: 10,
                color: AC.text(context),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 48),
            _goldDivider(),
            const SizedBox(height: 32),
            Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 26,
                color: AC.goldLight(context),
                height: 1.8,
              ),
            ),
            const SizedBox(height: 48),
            _goldDivider(),
          ],
        ),
      ),
    );
  }

  Widget _goldDivider() {
    return SizedBox(
      width: 200,
      child: Row(
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
      ),
    );
  }
}
