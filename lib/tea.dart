import 'dart:convert';

class Tea {
  final int? id;
  final String name;
  final String year;
  final String type;
  final String imgURL;
  final String description;
  final List<String> descriptors;

  Tea({
    this.id,
    required this.name,
    required this.year,
    required this.type,
    required this.imgURL,
    required this.description,
    required this.descriptors,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'type': type,
      'imgURL': imgURL,
      'description': description,
      'descriptors': descriptors.join(','), // для БД в виде строки
    };
  }

  factory Tea.fromMap(Map<String, dynamic> map) {
    return Tea(
      id: map['id'],
      name: map['name'] ?? '',
      year: map['year']?.toString() ?? '',
      type: map['type'] ?? '',
      imgURL: map['imgURL'] ?? '',
      description: map['description'] ?? '',
      descriptors: (map['descriptors'] is String)
          ? (map['descriptors'] as String).split(',')
          : (map['descriptors'] is List
          ? List<String>.from(map['descriptors'])
          : <String>[]),
    );
  }

  factory Tea.fromJsonString(String json) {
    final map = jsonDecode(json);
    return Tea(
      id: map['id'],
      name: map['name'] ?? '',
      year: map['year']?.toString() ?? '',
      type: map['type'] ?? '',
      imgURL: map['imgURL'] ?? '',
      description: map['description'] ?? '',
      descriptors: (map['descriptors'] is List)
          ? List<String>.from(map['descriptors'])
          : (map['descriptors'] is String
          ? (map['descriptors'] as String).split(',')
          : <String>[]),
    );
  }
}
