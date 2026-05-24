import 'dart:async';

import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  StreamSubscription<Object?>? _subscription;
  final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.qrCode],
  );

  void onData(BarcodeCapture capture) {
    final data = capture.barcodes.first.rawValue;

    if (data != null) {
      final documentId = data.trim();
      validateAndFetchDocument(documentId);
    }
  }

  Future<void> validateAndFetchDocument(String documentId) async {
    
    if (documentId.isEmpty || documentId.length < 15) {
      return;
    }

    if(!documentId.startsWith('phone_')){
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(documentId).get();

      if (doc.exists) {
        final user = UserModel.fromFirestore(doc);
        if (!user.isKid) {
          SnackBarSerive.showErrorSnackBar('scanKidQR'.tr());
        } else {
          controller.stop();
          if (mounted) context.pop(user);
        }
      } else {
        SnackBarSerive.showErrorSnackBar('userNotFound'.tr());
        return;
      }
    } catch (e) {
      SnackBarSerive.showErrorSnackBar('${'defaultErrorText'.tr()}: $e');

      return;
    }
  }

  @override
  void initState() {
    super.initState();

    controller.start();
    _subscription = controller.barcodes.listen(onData);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWidth = size.width - (48);
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.sizeOf(context).center(Offset.zero) - const Offset(0, 10),
      width: scanWidth,
      height: scanWidth,
    );
    final scanAreaSize = size.width - (48);
    return Scaffold(
      backgroundColor: white,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (BarcodeCapture capture) {},
          ),
          CustomPaint(
            size: size,
            painter: ScanOverlayPainter(
              scanAreaSize: scanAreaSize,
              screenSize: size,
            ),
          ),
          Center(
            child: CustomPaint(
              size: Size(scanAreaSize, scanAreaSize),
              painter: CornerOverlayPainter(),
            ),
          ),
          title(),
        ],
      ),
    );
  }

  Widget title() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.clear, size: 30, color: white),
              onPressed: () => context.pop(),
            ),
             Expanded(
              child: AppText(
                text: 'scan_qr_code'.tr(),
                size: 24,
                fw: FontWeight.w700,
                color: white,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 30),
          ],
        ),
      ),
    );
  }
}

class CornerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primary900
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const double cornerLength = 60; 
    const double cornerRadius = 10; 

    
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, cornerRadius)
        ..quadraticBezierTo(0, 0, cornerRadius, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

  
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width - cornerRadius, 0)
        ..quadraticBezierTo(size.width, 0, size.width, cornerRadius)
        ..lineTo(size.width, cornerLength),
      paint,
    );


    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - cornerLength)
        ..lineTo(size.width, size.height - cornerRadius)
        ..quadraticBezierTo(size.width, size.height, size.width - cornerRadius, size.height)
        ..lineTo(size.width - cornerLength, size.height),
      paint,
    );

   
    canvas.drawPath(
      Path()
        ..moveTo(cornerLength, size.height)
        ..lineTo(cornerRadius, size.height)
        ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
        ..lineTo(0, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Size screenSize;

  ScanOverlayPainter({required this.scanAreaSize, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, screenSize.width, screenSize.height))
        ..addRect(Rect.fromCenter(
          center: Offset(screenSize.width / 2, screenSize.height / 2),
          width: scanAreaSize,
          height: scanAreaSize,
        ))
        ..fillType = PathFillType.evenOdd,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
