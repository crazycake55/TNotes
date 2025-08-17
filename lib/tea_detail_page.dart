import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'tea.dart';
import 'flavour_data.dart';

class TeaDetailPage extends StatefulWidget {
  final Tea tea;

  const TeaDetailPage({super.key, required this.tea});

  @override
  State<TeaDetailPage> createState() => _TeaDetailPageState();
}

class _TeaDetailPageState extends State<TeaDetailPage> {
  final GlobalKey _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final descriptors = widget.tea.descriptors is List
        ? (widget.tea.descriptors as List).join(', ')
        : widget.tea.descriptors.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Tea Details')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showTeaCardOverlay,
        icon: const Icon(Icons.photo, color: Colors.white),
        label: const Text('Generate Card'),
        backgroundColor: const Color(0xFFCD1C0E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (widget.tea.imgURL.trim().isEmpty) return;
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        insetPadding: const EdgeInsets.all(16),
                        child: InteractiveViewer(
                          child: CachedNetworkImage(
                            imageUrl: widget.tea.imgURL.trim(),
                            fit: BoxFit.contain,
                            placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                            errorWidget: (_, __, ___) => placeholderError(),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.tea.imgURL.trim().isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: widget.tea.imgURL.trim(),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                      errorWidget: (_, __, ___) => placeholderError(),
                    )
                        : placeholderError(),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.zoom_in, color: Colors.white),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            _buildInfoRow('Name:', widget.tea.name, isDark),
            const SizedBox(height: 12),
            _buildInfoRow('Type:', widget.tea.type, isDark),
            const SizedBox(height: 12),
            _buildInfoRow('Note:', widget.tea.description, isDark),
            const SizedBox(height: 12),
            _buildInfoRow('Year:', widget.tea.year.toString(), isDark),
            const SizedBox(height: 24),
            Text(
              'Descriptors:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            buildDescriptorsChips(descriptors.split(',')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget buildDescriptorsChips(List<String> descriptors) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: descriptors.map((descriptor) {
        final trimmed = descriptor.trim();
        final group = flavorGroups.entries.firstWhere(
              (entry) => entry.value.contains(trimmed),
          orElse: () => const MapEntry('Unknown', []),
        ).key;
        final color = groupColors[group] ?? Colors.grey;

        return Chip(
          label: Text(trimmed),
          backgroundColor: color,
          labelStyle: const TextStyle(color: Colors.black),
        );
      }).toList(),
    );
  }

  void showTeaCardOverlay() {
    Color cardColor = Colors.white;
    Color textColor = Colors.black;

    void updateCardColor(Color newColor, void Function(void Function()) setState) {
      cardColor = newColor;
      textColor = ThemeData.estimateBrightnessForColor(newColor) == Brightness.dark
          ? Colors.white
          : Colors.black;
      setState(() {});
    }

    Widget buildColorButton(Color color, void Function(void Function()) setState) {
      return GestureDetector(
        onTap: () => updateCardColor(color, setState),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26),
          ),
        ),
      );
    }

    final teaLink = Uri(
      scheme: 'tnotes',
      host: 'import-tea',
      queryParameters: {
        'name': widget.tea.name,
        'description': widget.tea.description,
        'type': widget.tea.type,
        'imgURL': widget.tea.imgURL,
        'year': widget.tea.year.toString(),
        'descriptors': widget.tea.descriptors.join(','),
      },
    ).toString();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Center(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RepaintBoundary(
                    key: _cardKey,
                    child: Container(
                      width: 300,
                      height: 400,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 10)
                        ],
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: widget.tea.imgURL.trim().isNotEmpty
                                        ? CachedNetworkImage(
                                      imageUrl: widget.tea.imgURL.trim(),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => placeholderImage(),
                                      errorWidget: (_, __, ___) => placeholderImage(),
                                    )
                                        : placeholderImage(),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _truncateTitle(widget.tea.name),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.tea.description,
                                          style: TextStyle(fontSize: 16, color: textColor),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Type:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                widget.tea.type,
                                style: TextStyle(color: textColor, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Descriptors:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _truncateDescriptors(widget.tea.descriptors),
                                style: TextStyle(color: textColor, fontSize: 15),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: QrImageView(
                                data: teaLink,
                                version: QrVersions.auto,
                                size: 140,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: shareCardAsImage,
                        icon: const Icon(Icons.share, color: Colors.white),
                        label: const Text('Share PNG'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCD1C0E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          buildColorButton(Colors.white, setState),
                          buildColorButton(Colors.green.shade100, setState),
                          buildColorButton(Colors.amber.shade100, setState),
                          buildColorButton(Colors.blue.shade200, setState),
                          buildColorButton(Colors.red.shade900, setState),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _truncateTitle(String title) {
    return title.length <= 22 ? title : '${title.substring(0, 22).trim()}...';
  }

  String _truncateDescriptors(List<String> descriptors) {
    final full = descriptors.join(', ');
    if (full.length <= 77) return full;
    String truncated = full.substring(0, 85);
    final lastComma = truncated.lastIndexOf(',');
    return '${(lastComma != -1 ? truncated.substring(0, lastComma) : truncated).trim()}...';
  }

  Widget placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  Widget placeholderError() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Center(
        child: Text(
          '⚠️ Image not found\nor no network connection',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
    );
  }

  Future<void> shareCardAsImage() async {
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tea_card.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out my tea card!\nMade in TNotes app');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }
}
