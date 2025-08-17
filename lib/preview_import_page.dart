import 'package:flutter/material.dart';
import 'tea.dart';
import 'tea_detail_page.dart';
import 'database_helper.dart';

class PreviewImportPage extends StatelessWidget {
  final List<Tea> teas;

  const PreviewImportPage({super.key, required this.teas});

  Future<void> _importTeas(BuildContext context) async {
    for (final tea in teas) {
      await DatabaseHelper.instance.insertTea(tea);
    }

    if (context.mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teas were imported successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collection preview')),
      body: ListView.builder(
        itemCount: teas.length,
        itemBuilder: (context, index) {
          final tea = teas[index];
          return ListTile(
            leading: tea.imgURL.trim().isNotEmpty
                ? Image.network(tea.imgURL, width: 40, height: 40, fit: BoxFit.cover)
                : const Icon(Icons.local_drink),
            title: Text(tea.name),
            subtitle: Text('${tea.year} • ${tea.type}'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeaDetailPage(tea: tea)),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _importTeas(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCD1C0E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Import'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
