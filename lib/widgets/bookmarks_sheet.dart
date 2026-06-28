import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/bookmark_service.dart';
import '../providers/quran_provider.dart';
import '../screens/reading_screen.dart';

Future<void> showBookmarksSheet(BuildContext outerContext) async {
  List<String> bookmarks = await BookmarkService.getAllBookmarks();
  if (!outerContext.mounted) return;
  showModalBottomSheet(
    context: outerContext,
    backgroundColor: AC.surface(outerContext),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => StatefulBuilder(
      builder: (context, setSheetState) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Padding(
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
                  Icon(Icons.bookmark, color: AC.gold(context), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'المحفوظات',
                    style: TextStyle(
                      color: AC.gold(context),
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (bookmarks.isNotEmpty)
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AC.surface(context),
                            title: Text(
                              'مسح الكل',
                              style: TextStyle(color: AC.gold(context)),
                            ),
                            content: Text(
                              'هل أنت متأكد من مسح جميع المحفوظات؟',
                              style: TextStyle(color: AC.text(context)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(
                                  'إلغاء',
                                  style: TextStyle(color: AC.text(context)),
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'مسح الكل',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await BookmarkService.clearAllBookmarks();
                          bookmarks = await BookmarkService.getAllBookmarks();
                          setSheetState(() {});
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'مسح الكل',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.redAccent.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: bookmarks.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد محفوظات بعد',
                          style: TextStyle(
                            color: AC.text(context),
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: bookmarks.length,
                        itemBuilder: (_, i) {
                          final parts = bookmarks[i].split(':');
                          final surahNum = int.parse(parts[0]);
                          final ayahNum = int.parse(parts[1]);
                          final text = parts.sublist(2).join(':');
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              Future.microtask(() {
                                if (outerContext.mounted) {
                                  outerContext
                                      .read<QuranProvider>()
                                      .loadAyahs(surahNum);
                                  Navigator.push(
                                    outerContext,
                                    MaterialPageRoute(
                                      builder: (_) => ReadingScreen(
                                        surahNumber: surahNum,
                                        scrollToAyah: ayahNum,
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AC.bg(context),
                                border: Border.all(color: AC.border(context)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AC.surface(context),
                                          title: Text(
                                            'حذف المحفوظة',
                                            style: TextStyle(
                                              color: AC.gold(context),
                                            ),
                                          ),
                                          content: Text(
                                            'هل أنت متأكد من حذف هذه الآية من المحفوظات؟',
                                            style: TextStyle(
                                              color: AC.text(context),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: Text(
                                                'إلغاء',
                                                style: TextStyle(
                                                  color: AC.text(context),
                                                ),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: Text(
                                                'حذف',
                                                style: TextStyle(
                                                  color: Colors.redAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await BookmarkService.removeBookmark(
                                          surahNum,
                                          ayahNum,
                                        );
                                        bookmarks = await BookmarkService
                                            .getAllBookmarks();
                                        setSheetState(() {});
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent
                                            .withValues(alpha: 0.7),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          text,
                                          textDirection: TextDirection.rtl,
                                          style: GoogleFonts.amiri(
                                            fontSize: 16,
                                            color: AC.goldLight(context),
                                            height: 1.8,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'سورة $surahNum — الآية $ayahNum',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AC.text(context),
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
