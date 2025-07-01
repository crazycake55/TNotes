import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void startScan() {
    setState(() {
      isScanning = true;
    });
    cameraController.start();
  }

  void stopScan() {
    setState(() {
      isScanning = false;
    });
    cameraController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Column(
        children: [
          Expanded(
            child: isScanning
                ? MobileScanner(
              controller: cameraController,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final rawValue = barcodes.first.rawValue;
                    if (rawValue != null && isScanning) {
                      stopScan();
                      Navigator.pop(context, rawValue);
                    }
                  }
                },
              )
              : Center(child: Text('Press the button to start scanning')),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: Icon(isScanning ? Icons.stop : Icons.qr_code_scanner),
              label: Text(isScanning ? 'Stop Scanning' : 'Start Scanning'),
              onPressed: () {
                if (isScanning) {
                  stopScan();
                } else {
                  startScan();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
