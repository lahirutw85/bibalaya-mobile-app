import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bible_provider.dart';
import '../models/bible_verse.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  @override
  void initState() {
    super.initState();
    // Enable compare mode automatically on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BibleProvider>(context, listen: false).toggleCompareMode(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibleProvider>(context);
    final theme = Theme.of(context);
    final isDark = provider.isDarkTheme;

    final versions = ["ROV", "2018", "SINBIBLE", "TAMOVR", "BSB", "KJV", "NIV", "AMP"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("පරිවර්තන සංසන්දනය / Compare"),
        actions: [
          Row(
            children: [
              const Text("3-Way Compare", style: TextStyle(fontSize: 12)),
              Switch(
                value: provider.threeWayCompare,
                onChanged: (val) => provider.toggleThreeWayCompare(val),
              ),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          // Select Comparison Versions bar
          Container(
            padding: const EdgeInsets.all(12.0),
            color: theme.cardColor,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Translation 1", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: provider.version,
                        underline: const SizedBox.shrink(),
                        onChanged: (val) {
                          if (val != null) provider.setVersion(val);
                        },
                        items: versions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Translation 2", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: provider.compareVersion,
                        underline: const SizedBox.shrink(),
                        onChanged: (val) {
                          if (val != null) provider.setCompareVersion(val);
                        },
                        items: versions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      ),
                    ],
                  ),
                ),
                if (provider.threeWayCompare) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Translation 3", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: provider.compareVersion3,
                          underline: const SizedBox.shrink(),
                          onChanged: (val) {
                            if (val != null) provider.setCompareVersion3(val);
                          },
                          items: versions.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        ),
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          
          // Parallel Verses List
          Expanded(
            child: (provider.loading || provider.compareLoading || (provider.threeWayCompare && provider.compareLoading3))
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: provider.verses.length,
                    itemBuilder: (context, index) {
                      final v1 = provider.verses[index];
                      
                      // Safely align by index coordinates
                      BibleVerse? v2;
                      if (index < provider.compareVerses.length) {
                        v2 = provider.compareVerses[index];
                      }
                      
                      BibleVerse? v3;
                      if (provider.threeWayCompare && index < provider.compareVerses3.length) {
                        v3 = provider.compareVerses3[index];
                      }

                      return _buildParallelCard(v1, v2, v3, provider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildParallelCard(BibleVerse v1, BibleVerse? v2, BibleVerse? v3, BibleProvider provider) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verse Coordinates Header
            Text(
              "${v1.book} ${v1.chapter}:${v1.verse}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
                fontSize: 13,
              ),
            ),
            const Divider(height: 12),
            
            // Version 1 Text
            _buildTranslationText(provider.version, v1.text, provider.fontSize),
            
            if (v2 != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 8),
              // Version 2 Text
              _buildTranslationText(provider.compareVersion, v2.text, provider.fontSize),
            ],

            if (provider.threeWayCompare && v3 != null) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: Colors.grey),
              const SizedBox(height: 8),
              // Version 3 Text
              _buildTranslationText(provider.compareVersion3, v3.text, provider.fontSize),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationText(String ver, String text, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            ver,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontSize: fontSize - 1, height: 1.4),
        ),
      ],
    );
  }
}
