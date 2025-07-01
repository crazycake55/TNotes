import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'flavour_data.dart';

class AddTeaPage extends StatefulWidget {
  final Map<String, dynamic>? existingTea;

  const AddTeaPage({super.key, this.existingTea});

  @override
  State<AddTeaPage> createState() => _AddTeaPageState();
}

class _AddTeaPageState extends State<AddTeaPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController yearController = TextEditingController();
  final TextEditingController imgUrlController = TextEditingController();
  String selectedType = '';
  final Set<String> selectedDescriptors = {};

  final List<String> teaTypes = [
    'Green',
    'Black',
    'Dark',
    'Oolong',
    'White',
    'Herbal',
    'Pu-erh'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTea != null) {
      nameController.text = widget.existingTea!['name'] ?? '';
      descriptionController.text = widget.existingTea!['description'] ?? '';
      imgUrlController.text = widget.existingTea!['imgURL'] ?? '';
      selectedType = widget.existingTea!['type'] ?? '';
      final year = widget.existingTea!['year'];
      yearController.text = year != null ? year.toString() : '';

      final descriptors = widget.existingTea!['descriptors'] as String?;
      if (descriptors != null && descriptors.isNotEmpty) {
        selectedDescriptors.addAll(
          descriptors.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
        );
      }
    }
  }

  void saveTea() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();
    final imgUrl = imgUrlController.text.trim();
    final year = int.tryParse(yearController.text.trim());
    final descriptors = selectedDescriptors.toList();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter name of tea')),
      );
      return;
    }

    final db = await DatabaseHelper.instance.database;

    final teaData = {
      'name': name,
      'description': description,
      'year': year,
      'descriptors': descriptors.join(','),
      'imgURL': imgUrl,
      'type': selectedType,
    };

    if (widget.existingTea == null) {
      await db.insert('teas', teaData);
    } else {
      await db.update(
        'teas',
        teaData,
        where: 'id = ?',
        whereArgs: [widget.existingTea!['id']],
      );
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingTea != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit tea information' : 'Add new tea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name of tea',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imgUrlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedType.isEmpty ? null : selectedType,
              items: teaTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Type of tea',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  selectedType = value ?? '';
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('Select flavours:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: flavorGroups.entries.map((entry) {
                    final group = entry.key;
                    final descriptors = entry.value;
                    final groupColor = groupColors[group] ?? Colors.grey;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: groupColor,
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: descriptors.map((desc) {
                            return FilterChip(
                              label: Text(desc),
                              selected: selectedDescriptors.contains(desc),
                              selectedColor: groupColor.withOpacity(0.3),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedDescriptors.add(desc);
                                  } else {
                                    selectedDescriptors.remove(desc);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: saveTea,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Apply changes' : 'Save new tea'),
            ),
          ],
        ),
      ),
    );
  }
}
