import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../services/reference_service.dart';

class CrossReferencePanel extends StatelessWidget {
  final int panelIndex;
  final PanelCoordinate coordinate;
  final VoidCallback onClose;

  const CrossReferencePanel({
    super.key,
    required this.panelIndex,
    required this.coordinate,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              key: ValueKey(panelIndex),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "${coordinate.book} ${coordinate.chapter}:${coordinate.verse} (Ref level ${panelIndex + 1})",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  )
                ],
              ),
            ),
            const Divider(height: 1),
            // Panel Content
            Expanded(
              child: FutureBuilder<String?>(
                future: provider.bibleService.fetchSingleVerse(
                  coordinate.book,
                  coordinate.chapter,
                  coordinate.verse,
                  coordinate.version,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final text = snapshot.data;
                  if (text == null) {
                    return const Center(child: Text("Verse not found"));
                  }

                  return Column(
                    children: [
                      // Verse Text block
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: provider.fontSize - 1,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // Cross references inside this referenced verse
                      Expanded(
                        child: FutureBuilder<Map<String, List<BibleReference>>>(
                          future: provider.bibleService.fetchChapter(
                            coordinate.book,
                            coordinate.chapter,
                            coordinate.version,
                          ).then((verses) {
                            final refServ = ReferenceService();
                            final filtered = verses.where((v) => 
                              v.book == coordinate.book && 
                              v.chapter == coordinate.chapter && 
                              v.verse == coordinate.verse
                            ).toList();
                            return refServ.fetchReferencesForChapter(filtered);
                          }),
                          builder: (context, refSnapshot) {
                            if (refSnapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final refsMap = refSnapshot.data;
                            final key = "${coordinate.book}_${coordinate.chapter}_${coordinate.verse}";
                            final refsList = refsMap?[key] ?? [];

                            if (refsList.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No nested references",
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              itemCount: refsList.length,
                              itemBuilder: (context, index) {
                                final ref = refsList[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    "${ref.book} ${ref.chapter}:${ref.verse}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 10),
                                  onTap: () {
                                    provider.openReferencePanel(ref.book, ref.chapter, ref.verse);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
