import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("සුරැකි පද / Bookmarks"),
      ),
      body: provider.bookmarks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "සුරැකි පද නොමැත.\n(No bookmarks saved.)",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = provider.bookmarks[index];
                
                Color itemColor;
                try {
                  final hexStr = bookmark.color.replaceAll("#", "");
                  itemColor = Color(int.parse("0xFF$hexStr"));
                } catch (_) {
                  itemColor = Colors.yellow;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    side: BorderSide(color: itemColor.withOpacity(0.5), width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${bookmark.book} ${bookmark.chapter}:${bookmark.verse}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                        // Indicator dot representing bookmark highlight color
                        CircleAvatar(
                          backgroundColor: itemColor,
                          radius: 6,
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        bookmark.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: provider.fontSize - 2,
                          height: 1.4,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () {
                        provider.removeBookmark(bookmark.book, bookmark.chapter, bookmark.verse);
                      },
                    ),
                    onTap: () async {
                      // Navigate to reading screen coordinates
                      if (bookmark.version.isNotEmpty && bookmark.version != provider.version) {
                        await provider.setVersion(bookmark.version);
                      }
                      await provider.setSelectedBook(bookmark.book);
                      await provider.setSelectedChapter(bookmark.chapter);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
