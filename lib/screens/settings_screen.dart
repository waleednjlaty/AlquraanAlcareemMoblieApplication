import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../providers/quran_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aboutKey = GlobalKey();

  // ── القراء (المفاتيح من everyayah.com/data) ────
  final List<Map<String, String>> _reciters = [
    {'name': 'مشاري العفاسي', 'key': 'Alafasy_128kbps'},
    {'name': 'ياسر الدوسري', 'key': 'Yasser_Ad-Dussary_128kbps'},
    {'name': 'عبد الباسط', 'key': 'Abdul_Basit_Murattal_64kbps'},
    {'name': 'محمود الحصري', 'key': 'Husary_128kbps'},
    {'name': 'سعد الغامدي', 'key': 'Ghamadi_40kbps'},
    {'name': 'ماهر المعيقلي', 'key': 'MaherAlMuaiqly128kbps'},
  ];

  // ── فتح الروابط ────────────────────────────────
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر فتح الرابط',
              style: GoogleFonts.amiri(color: AC.bg(context)),
            ),
            backgroundColor: AC.gold(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // ── سكرول لقسم عن التطبيق ──────────────────────
  void _scrollToAbout() {
    final ctx = _aboutKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();

    return Scaffold(
      backgroundColor: AC.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  // ══ العرض ══════════════════════════
                  _sectionLabel(context, 'العرض'),
                  const SizedBox(height: 8),

                  // وضع الليل
                  _buildTile(
                    context,
                    icon: provider.isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: provider.isDarkMode ? 'وضع الليل' : 'وضع النهار',
                    subtitle: 'تغيير مظهر التطبيق',
                    trailing: Switch(
                      value: provider.isDarkMode,
                      onChanged: (_) => provider.toggleTheme(),
                      activeColor: AC.gold(context),
                    ),
                  ),

                  // حجم الخط
                  _buildTile(
                    context,
                    icon: Icons.format_size_outlined,
                    title: 'حجم الخط الافتراضي',
                    subtitle: 'حجم خط الآيات عند الفتح',
                    trailing: _buildFontSizeControl(context, provider),
                  ),
                  const SizedBox(height: 20),

                  // ══ الصوت ══════════════════════════
                  _sectionLabel(context, 'الصوت'),
                  const SizedBox(height: 8),

                  // تشغيل تلقائي
                  _buildTile(
                    context,
                    icon: Icons.playlist_play_outlined,
                    title: 'تشغيل تلقائي للآيات',
                    subtitle: 'الانتقال للآية التالية تلقائياً',
                    trailing: Switch(
                      value: provider.autoPlay,
                      onChanged: (val) => provider.setAutoPlay(val),
                      activeColor: AC.gold(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // اختيار القارئ
                  _sectionLabel(context, 'اختيار القارئ', small: true),
                  const SizedBox(height: 8),
                  ..._reciters.map(
                    (r) => _buildReciterTile(
                      context,
                      provider,
                      r['name']!,
                      r['key']!,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ══ التطبيق ════════════════════════
                  _sectionLabel(context, 'التطبيق'),
                  const SizedBox(height: 8),

                  // عن التطبيق — يسكرول لأسفل
                  _buildTile(
                    context,
                    icon: Icons.info_outline,
                    title: 'عن التطبيق والدعم',
                    subtitle: 'معلومات التطبيق والمطور',
                    onTap: _scrollToAbout,
                  ),
                  const SizedBox(height: 32),

                  // ══ قسم عن التطبيق ═════════════════
                  _buildAboutSection(context),
                ],
              ),
            ),
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
            'الإعدادات',
            style: GoogleFonts.amiri(
              fontSize: 22,
              color: AC.gold(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── عنصر الإعداد ───────────────────────────────
  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AC.gold(context).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AC.gold(context), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AC.goldLight(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: AC.text(context), fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
              Icon(Icons.arrow_back_ios, color: AC.text(context), size: 14),
          ],
        ),
      ),
    );
  }

  // ── التحكم بحجم الخط ───────────────────────────
  Widget _buildFontSizeControl(BuildContext context, QuranProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _fontBtn(context, Icons.remove, () {
          if (provider.defaultFontSize > 14) {
            provider.setFontSize(provider.defaultFontSize - 2);
          }
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${provider.defaultFontSize.toInt()}',
            style: TextStyle(
              color: AC.gold(context),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _fontBtn(context, Icons.add, () {
          if (provider.defaultFontSize < 32) {
            provider.setFontSize(provider.defaultFontSize + 2);
          }
        }),
      ],
    );
  }

  Widget _fontBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AC.border(context)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AC.gold(context), size: 14),
      ),
    );
  }

  // ── عنصر القارئ ────────────────────────────────
  Widget _buildReciterTile(
    BuildContext context,
    QuranProvider provider,
    String name,
    String key,
  ) {
    final isSelected = provider.reciterKey == key;
    return GestureDetector(
      onTap: () => provider.setReciter(key, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AC.gold(context).withValues(alpha: 0.10)
              : AC.surface(context),
          border: Border.all(
            color: isSelected ? AC.borderMid(context) : AC.border(context),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? AC.gold(context) : AC.text(context),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? AC.gold(context) : AC.goldLight(context),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AC.gold(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'محدد',
                  style: TextStyle(
                    color: AC.gold(context),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── عنوان القسم ────────────────────────────────
  Widget _sectionLabel(
    BuildContext context,
    String label, {
    bool small = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, right: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: small ? 11 : 12,
          color: AC.gold(context),
          letterSpacing: 2,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ══ قسم عن التطبيق والدعم ══════════════════════
  Widget _buildAboutSection(BuildContext context) {
    return Container(
      key: _aboutKey,
      decoration: BoxDecoration(
        color: AC.surface(context),
        border: Border.all(color: AC.borderMid(context)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // ── هيدر ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AC.gold(context).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AC.gold(context).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AC.borderMid(context)),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: AC.gold(context),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'القرآن الكريم',
                  style: GoogleFonts.amiri(
                    fontSize: 22,
                    color: AC.gold(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الإصدار ١٫٠٫٠',
                  style: TextStyle(
                    fontSize: 11,
                    color: AC.text(context),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── التعليمات ──────────────────
                _aboutCard(
                  context,
                  icon: Icons.info_outline,
                  title: 'التعليمات',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _infoRow(
                        context,
                        Icons.wifi_off_outlined,
                        'القراءة تعمل بدون إنترنت ',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.wifi_outlined,
                        'الاستماع يحتاج اتصال بالإنترنت',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.touch_app_outlined,
                        'اضغط على رقم الآية لتحديدها',
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.pan_tool_outlined,
                        'اضغط مطولاً على الآية للاستماع',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── عن المطور ──────────────────
                _aboutCard(
                  context,
                  icon: Icons.person_outline,
                  title: 'عن المطور',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'وليد النجلات ',
                        style: TextStyle(
                          color: AC.goldLight(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'طالب فين تقانة المعلومات\nاطمح أن اكون مطورًا رياديًا ومبتكرًا تقنيًا',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AC.text(context),
                          fontSize: 12,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── الدعم والتواصل ─────────────
                _aboutCard(
                  context,
                  icon: Icons.support_outlined,
                  title: 'الدعم والتواصل',
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: [
                      _contactBtn(
                        context,
                        icon: Icons.code,
                        label: 'GitHub',
                        url: 'https://github.com/waleednjlaty',
                      ),
                      _contactBtn(
                        context,
                        icon: Icons.work_outline,
                        label: 'LinkedIn',
                        url:
                            'https://linkedin.com/in/waleed-al-najlat-6634a1295',
                      ),
                      _contactBtn(
                        context,
                        icon: Icons.play_circle_outline,
                        label: 'YouTube',
                        url:
                            'https://youtube.com/@dev.waleedal-njlat?si=3oaA3kPn19s#WKNW',
                      ),
                      _contactBtn(
                        context,
                        icon: Icons.email_outlined,
                        label: 'تواصل',
                        url: 'mailto:waleed.njlatty@gmail.com',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── مصادر البيانات ──────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AC.bg(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AC.border(context)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'مصادر البيانات',
                        style: TextStyle(
                          color: AC.gold(context),
                          fontSize: 11,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        Icons.storage_outlined,
                        'بيانات القرآن: مدمجة بالتطبيق',
                      ),
                      const SizedBox(height: 4),
                      _infoRow(
                        context,
                        Icons.volume_up_outlined,
                        'الصوت: everyayah.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── الدعم المادي ────────────────
                _aboutCard(
                  context,
                  icon: Icons.favorite_outline,
                  title: 'الدعم المادي',
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(
                              text: 'waleedfacebook12@gmail.com',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ تم نسخ الإيميل'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AC.gold(context).withValues(alpha: 0.08),
                            border: Border.all(color: AC.borderMid(context)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'PayPal',
                                style: TextStyle(
                                  color: AC.gold(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'waleedfacebook12@gmail.com',
                                  style: TextStyle(
                                    color: AC.text(context),
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    color: AC.gold(context),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'اضغط للنسخ',
                                    style: TextStyle(
                                      color: AC.gold(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            const ClipboardData(
                              text: 'TD3S1HrR43vneeLZSTQJvomEEfxNsnvZDh',
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ تم نسخ العنوان'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AC.gold(context).withValues(alpha: 0.08),
                            border: Border.all(color: AC.borderMid(context)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'USDT (TRC20)',
                                style: TextStyle(
                                  color: AC.gold(context),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  'TD3S1HrR43vneeLZSTQJvomEEfxNsnvZDh',
                                  style: TextStyle(
                                    color: AC.text(context),
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.copy_rounded,
                                    color: AC.gold(context),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'اضغط للنسخ',
                                    style: TextStyle(
                                      color: AC.gold(context),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── كارت معلومات ───────────────────────────────
  Widget _aboutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AC.bg(context),
        border: Border.all(color: AC.border(context)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AC.gold(context),
                  fontSize: 13,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AC.gold(context), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  // ── سطر معلومة ─────────────────────────────────
  Widget _infoRow(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(color: AC.text(context), fontSize: 12),
        ),
        const SizedBox(width: 8),
        Icon(icon, color: AC.gold(context), size: 16),
      ],
    );
  }

  // ── زر تواصل ───────────────────────────────────
  Widget _contactBtn(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return GestureDetector(
      onTap: () => _launchUrl(url),
      child: Container(
        decoration: BoxDecoration(
          color: AC.gold(context).withValues(alpha: 0.08),
          border: Border.all(color: AC.borderMid(context)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AC.gold(context), size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: AC.gold(context),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
