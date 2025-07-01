import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import 'tea.dart';
import 'tea_detail_page.dart';
import 'add_tea_page.dart';
import 'tea_stats.dart';
import 'database_helper.dart';
import 'qr_scanner_page.dart';
import 'package:flutter/services.dart';
import 'package:app_links/app_links.dart';

class TeaListPage extends StatefulWidget {
  const TeaListPage({super.key});

  @override
  State<TeaListPage> createState() => _TeaListPageState();
}

class _TeaListPageState extends State<TeaListPage> {
  List<Tea> allTeas = [];
  List<Tea> filteredTeas = [];
  String searchQuery = '';
  String selectedYear = '';
  String selectedType = '';
  List<String> selectedDescriptors = [];
  bool showFilters = false;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    loadTeas();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();
    final initialUri = await _appLinks.getInitialAppLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _appLinks.uriLinkStream.listen((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _processScannedQRCode(String rawValue) async {
    Uri? uri;
    try {
      uri = Uri.parse(rawValue);
    } catch (_) {
      uri = null;
    }

    if (uri == null || uri.scheme != 'tnotes' || uri.host != 'import-tea') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR code')),
      );
      return;
    }

    final tea = Tea(
      name: uri.queryParameters['name'] ?? '',
      year: uri.queryParameters['year'] ?? '',
      type: uri.queryParameters['type'] ?? '',
      imgURL: uri.queryParameters['imgURL'] ?? '',
      description: uri.queryParameters['description'] ?? '',
      descriptors: uri.queryParameters['descriptors']?.split(',') ?? [],
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tea'),
        content: Text('Would you like to import "${tea.name}" into your collection?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.insertTea(tea);
      await loadTeas();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tea "${tea.name}" has been added')),
      );
    }
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'tnotes' && uri.host == 'import-tea') {
      final tea = Tea(
        name: uri.queryParameters['name'] ?? '',
        year: uri.queryParameters['year'] ?? '',
        type: uri.queryParameters['type'] ?? '',
        imgURL: uri.queryParameters['imgURL'] ?? '',
        description: uri.queryParameters['description'] ?? '',
        descriptors: uri.queryParameters['descriptors']?.split(',') ?? [],
      );

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Tea'),
          content: Text('Would you like to import "${tea.name}" into your collection?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await DatabaseHelper.instance.insertTea(tea);
        await loadTeas();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tea "${tea.name}" has been added')),
        );
      }
    }
  }

  Future<void> loadTeas() async {
    final teas = await DatabaseHelper.instance.getTeas();
    setState(() {
      allTeas = teas;
      filteredTeas = teas;
    });
  }

  void filterTeas() {
    setState(() {
      filteredTeas = allTeas.where((tea) {
        final matchesSearch = tea.name.toLowerCase().contains(searchQuery.toLowerCase());
        final matchesYear = selectedYear.isEmpty || tea.year == selectedYear;
        final matchesType = selectedType.isEmpty || tea.type == selectedType;
        final matchesDescriptors = selectedDescriptors.isEmpty || selectedDescriptors.every((d) => tea.descriptors.contains(d));
        return matchesSearch && matchesYear && matchesType && matchesDescriptors;
      }).toList();
      showFilters = searchQuery.isNotEmpty || selectedYear.isNotEmpty || selectedType.isNotEmpty || selectedDescriptors.isNotEmpty;
    });
  }

  TextEditingController searchController = TextEditingController();

  void resetFilters() {
    setState(() {
      searchController.clear();
      searchQuery = '';
      selectedYear = '';
      selectedType = '';
      selectedDescriptors = [];
      filteredTeas = allTeas;
      showFilters = false;
    });
  }

  Future<void> navigateToAddTea() async {
    await Navigator.pushNamed(context, '/add');
    await loadTeas();
  }

  Future<void> exportToJsonFile() async {
    try {
      final teas = await DatabaseHelper.instance.getTeas();
      final jsonString = jsonEncode(teas.map((t) => {
        'name': t.name,
        'year': t.year,
        'type': t.type,
        'imgURL': t.imgURL,
        'description': t.description,
        'descriptors': t.descriptors,
      }).toList());

      final bytes = utf8.encode(jsonString);

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/tea_collection_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(filePath)], text: 'My tea collection');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during export and share: $e')),
      );
    }
  }

  Future<void> importFromJsonFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected')),
        );
        return;
      }

      final filePath = result.files.single.path!;
      final file = File(filePath);
      final content = await file.readAsString();

      final List<dynamic> importedData = jsonDecode(content);

      for (var item in importedData) {
        final tea = Tea(
          name: item['name'] ?? '',
          year: item['year'] ?? '',
          type: item['type'] ?? '',
          imgURL: item['imgURL'] ?? '',
          description: item['description'] ?? '',
          descriptors: List<String>.from(item['descriptors'] ?? []),
        );
        await DatabaseHelper.instance.insertTea(tea);
      }

      await loadTeas();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully imported')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during import: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allYears = allTeas.map((t) => t.year).where((type) => type.isNotEmpty).toSet().toList()..sort();
    final allTypes = allTeas.map((t) => t.type).where((type) => type.isNotEmpty).toSet().toList()..sort();
    final allDescriptors = allTeas.expand((t) => t.descriptors).where((type) => type.isNotEmpty).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My teas'),
        actions: [
          if (showFilters)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: resetFilters,
              tooltip: 'Cancel filters',
            ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              tooltip: 'Open filters',
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (allYears.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by year',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedYear.isEmpty ? null : selectedYear,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All years')),
                    ...allYears.map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedYear = value ?? '';
                    });
                  },
                ),
              const SizedBox(height: 20),
              if (allTypes.isNotEmpty)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Filter by type',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedType.isEmpty ? null : selectedType,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All types')),
                    ...allTypes.map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedType = value ?? '';
                    });
                  },
                ),
              const SizedBox(height: 20),
              const Text('Filter by descriptors', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (allDescriptors.isNotEmpty)
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: allDescriptors.map((descriptor) {
                    final isSelected = selectedDescriptors.contains(descriptor);
                    return FilterChip(
                      label: Text(descriptor),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedDescriptors.add(descriptor);
                          } else {
                            selectedDescriptors.remove(descriptor);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  filterTeas();
                  Navigator.pop(context);
                },
                child: const Text('Apply filters'),
              )
            ],
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(image: DecorationImage(
               image: AssetImage('assets/ic_launcher.png'), repeat: ImageRepeat.repeat,
               ),
              ),
              child: Text('Menu', style: TextStyle(color: Colors.black, fontSize: 24, shadows: <Shadow>[
                       Shadow(
                         offset: Offset(1.0, 1.0),
                             blurRadius: 3.0,
                             color: Color.fromARGB(112, 0, 0, 0),
                         ),
                   ],)),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Import collection'),
              onTap: () async {
                Navigator.pop(context);
                await importFromJsonFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export collection'),
              onTap: () async {
                Navigator.pop(context);
                await exportToJsonFile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR code'),
              onTap: () async {
                Navigator.pop(context);
                final scannedData = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerPage()),
                );
                if (scannedData != null) {
                  _processScannedQRCode(scannedData);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TeaStatsPage(teas: allTeas),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ...filteredTeas.map((tea) {
                  return ListTile(
                    title: Text(tea.name),
                    subtitle: Text('Year: ${tea.year}, ${tea.descriptors.toString().replaceAll('[', '').replaceAll(']', '').replaceAll(',', ', ')}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TeaDetailPage(tea: tea)),
                      );
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddTeaPage(existingTea: tea.toMap()),
                            ),
                          );
                          await loadTeas();
                        } else if (value == 'delete') {
                          await DatabaseHelper.instance.deleteTea(tea.id!);
                          await loadTeas();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddTea,
        child: const Icon(Icons.add),
      ),
    );
  }
}
