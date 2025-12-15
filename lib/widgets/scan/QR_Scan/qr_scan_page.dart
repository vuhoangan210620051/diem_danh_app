import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  late final MobileScannerController controller;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose(); // 🧹 dọn camera
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Quét mã QR", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_scanned) return;

              final value = capture.barcodes.first.rawValue;
              if (value == null) return;

              _scanned = true;
              await controller.stop();

              if (mounted) Navigator.pop(context, value);
            },
          ),

          // Overlay với hình vuông
          _buildScanOverlay(context),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = size.width > 600
        ? 400.0 // Desktop/Web: cố định 400px
        : size.width * 0.7; // Mobile: 70% màn hình

    return Stack(
      children: [
        // Màn hình tối xung quanh
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: scanArea,
                  height: scanArea,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Khung viền và góc
        Center(
          child: Container(
            width: scanArea,
            height: scanArea,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2A3950), width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                // Góc trên trái
                Positioned(
                  top: -3,
                  left: -3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 6),
                        left: BorderSide(color: Colors.white, width: 6),
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Góc trên phải
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 6),
                        right: BorderSide(color: Colors.white, width: 6),
                      ),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Góc dưới trái
                Positioned(
                  bottom: -3,
                  left: -3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 6),
                        left: BorderSide(color: Colors.white, width: 6),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Góc dưới phải
                Positioned(
                  bottom: -3,
                  right: -3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.white, width: 6),
                        right: BorderSide(color: Colors.white, width: 6),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Hướng dẫn
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Đặt mã QR trong khung để quét",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
