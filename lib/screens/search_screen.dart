import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchScope = "global"; // "global" or "thisBook"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    final theme = Theme.of(context);
    final isDark = provider.isDarkTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("සෙවීම / Search"),
      ),
      body: Column(
        children: [
          // Search box controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "පද සොයන්න (Search)...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onSubmitted: (val) {
                    provider.performSearch(val, _searchScope);
                  },
                  onChanged: (val) {
                    setState(() {}); // Re-render suffix clear button
                  },
                ),
                const SizedBox(height: 8),
                // Scope selections
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Radio<String>(
                      value: "global",
                      groupValue: _searchScope,
                      onChanged: (val) {
                        setState(() {
                          _searchScope = val!;
                        });
                        if (_searchController.text.isNotEmpty) {
                          provider.performSearch(_searchController.text, _searchScope);
                        }
                      },
                    ),
                    const Text("සියලු පොත් (All Books)", style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 16),
                    Radio<String>(
                      value: "thisBook",
                      groupValue: _searchScope,
                      onChanged: (val) {
                        setState(() {
                          _searchScope = val!;
                        });
                        if (_searchController.text.isNotEmpty) {
                          provider.performSearch(_searchController.text, _searchScope);
                        }
                      },
                    ),
                    Text(
                      "මෙම පොතෙන් (${provider.selectedBook})",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: provider.searchLoading
                ? const Center(child: CircularProgressIndicator())
                : !provider.searchActive
                    ? const Center(
                        child: Text(
                          "සෙවුම් පදයක් ඇතුලත් කරන්න.\n(Enter query to start searching.)",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : provider.searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              "කිසිදු ප්‍රතිඵලයක් හමු නොවීය.\n(No results found.)",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            itemCount: provider.searchResults.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final res = provider.searchResults[index];
                              return ListTile(
                                title: Text(
                                  "${res.book} ${res.chapter}:${res.verse}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    res.text,
                                    style: TextStyle(
                                      fontSize: provider.fontSize - 2,
                                    ),
                                  ),
                                ),
                                onTap: () async {
                                  // Set selection in provider and jump to screen
                                  await provider.setSelectedBook(res.book);
                                  await provider.setSelectedChapter(res.chapter);
                                  provider.clearSearch();
                                  if (mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
