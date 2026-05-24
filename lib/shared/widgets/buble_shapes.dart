import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class LeftArrowBubleShape extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const LeftArrowBubleShape({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(30, 15, 10, 15),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LeftArrowCustomPainter(),
      child: Padding(padding: padding, child: child),
    );
  }
}

class BottomArrowBubleShape extends StatelessWidget {
  final Widget child;
  const BottomArrowBubleShape({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BottomArrowCustomPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 13),
        child: child,
      ),
    );
  }
}

class _LeftArrowCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width * 0.9955000, size.height * 0.9000000);
    path_0.cubicTo(size.width * 0.9955000, size.height * 0.9471375, size.width * 0.9955000, size.height * 0.9707125,
        size.width * 0.9846528, size.height * 0.9853563);
    path_0.cubicTo(
        size.width * 0.9738056, size.height, size.width * 0.9563472, size.height, size.width * 0.9214259, size.height);
    path_0.lineTo(size.width * 0.1590125, size.height);
    path_0.cubicTo(size.width * 0.1240935, size.height, size.width * 0.1066343, size.height, size.width * 0.09578611,
        size.height * 0.9853563);
    path_0.cubicTo(size.width * 0.08493843, size.height * 0.9707125, size.width * 0.08493843, size.height * 0.9471375,
        size.width * 0.08493843, size.height * 0.9000000);
    path_0.lineTo(size.width * 0.08493843, size.height * 0.6563875);
    path_0.cubicTo(size.width * 0.08493843, size.height * 0.6353313, size.width * 0.08493843, size.height * 0.6247994,
        size.width * 0.08205694, size.height * 0.6155231);
    path_0.cubicTo(size.width * 0.08126713, size.height * 0.6129800, size.width * 0.08032269, size.height * 0.6105288,
        size.width * 0.07923287, size.height * 0.6081956);
    path_0.cubicTo(size.width * 0.07525972, size.height * 0.5996862, size.width * 0.06887269, size.height * 0.5936431,
        size.width * 0.05609815, size.height * 0.5815562);
    path_0.lineTo(size.width * 0.05609815, size.height * 0.5815562);
    path_0.cubicTo(size.width * 0.02374315, size.height * 0.5509431, size.width * 0.007565741, size.height * 0.5356369,
        size.width * 0.005008796, size.height * 0.5149569);
    path_0.cubicTo(size.width * 0.004334935, size.height * 0.5095069, size.width * 0.004334875, size.height * 0.5039444,
        size.width * 0.005008611, size.height * 0.4984944);
    path_0.cubicTo(size.width * 0.007565139, size.height * 0.4778144, size.width * 0.02374278, size.height * 0.4625069,
        size.width * 0.05609815, size.height * 0.4318912);
    path_0.lineTo(size.width * 0.05609815, size.height * 0.4318912);
    path_0.cubicTo(size.width * 0.06887315, size.height * 0.4198031, size.width * 0.07526065, size.height * 0.4137594,
        size.width * 0.07923380, size.height * 0.4052494);
    path_0.cubicTo(size.width * 0.08032269, size.height * 0.4029169, size.width * 0.08126713, size.height * 0.4004669,
        size.width * 0.08205694, size.height * 0.3979244);
    path_0.cubicTo(size.width * 0.08493843, size.height * 0.3886475, size.width * 0.08493843, size.height * 0.3781175,
        size.width * 0.08493843, size.height * 0.3570575);
    path_0.lineTo(size.width * 0.08493843, size.height * 0.1000125);
    path_0.cubicTo(size.width * 0.08493843, size.height * 0.05287175, size.width * 0.08493843, size.height * 0.02930150,
        size.width * 0.09578611, size.height * 0.01465687);
    path_0.cubicTo(size.width * 0.1066343, size.height * 0.00001220700, size.width * 0.1240935,
        size.height * 0.00001220700, size.width * 0.1590125, size.height * 0.00001220700);
    path_0.lineTo(size.width * 0.9214259, size.height * 0.00001220700);
    path_0.cubicTo(size.width * 0.9563472, size.height * 0.00001220700, size.width * 0.9738056,
        size.height * 0.00001220700, size.width * 0.9846528, size.height * 0.01465687);
    path_0.cubicTo(size.width * 0.9955000, size.height * 0.02930150, size.width * 0.9955000, size.height * 0.05287175,
        size.width * 0.9955000, size.height * 0.1000125);
    path_0.lineTo(size.width * 0.9955000, size.height * 0.9000000);
    path_0.close();

    Paint paint0Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFEEEEEE);

    canvas.drawPath(path_0, paint0Stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _BottomArrowCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();
    path_0.moveTo(size.width, size.height * 0.5294118);
    path_0.cubicTo(size.width, size.height * 0.6403309, size.width, size.height * 0.6957897, size.width * 0.9853563,
        size.height * 0.7302485);
    path_0.cubicTo(size.width * 0.9707125, size.height * 0.7647059, size.width * 0.9471375, size.height * 0.7647059,
        size.width * 0.9000000, size.height * 0.7647059);
    path_0.lineTo(size.width * 0.6299063, size.height * 0.7647059);
    path_0.cubicTo(size.width * 0.6158931, size.height * 0.7647059, size.width * 0.6088875, size.height * 0.7647059,
        size.width * 0.6025294, size.height * 0.7687147);
    path_0.cubicTo(size.width * 0.5940512, size.height * 0.7740603, size.width * 0.5863213, size.height * 0.7845618,
        size.width * 0.5801150, size.height * 0.7991632);
    path_0.cubicTo(size.width * 0.5754606, size.height * 0.8101162, size.width * 0.5719575, size.height * 0.8243912,
        size.width * 0.5649519, size.height * 0.8529412);
    path_0.lineTo(size.width * 0.5649519, size.height * 0.8529412);
    path_0.cubicTo(size.width * 0.5460525, size.height * 0.9299647, size.width * 0.5366025, size.height * 0.9684779,
        size.width * 0.5250000, size.height * 0.9842397);
    path_0.cubicTo(size.width * 0.5095300, size.height * 1.005254, size.width * 0.4904700, size.height * 1.005254,
        size.width * 0.4750000, size.height * 0.9842397);
    path_0.cubicTo(size.width * 0.4633975, size.height * 0.9684779, size.width * 0.4539475, size.height * 0.9299647,
        size.width * 0.4350481, size.height * 0.8529412);
    path_0.lineTo(size.width * 0.4350481, size.height * 0.8529412);
    path_0.cubicTo(size.width * 0.4280425, size.height * 0.8243912, size.width * 0.4245394, size.height * 0.8101162,
        size.width * 0.4198850, size.height * 0.7991632);
    path_0.cubicTo(size.width * 0.4136787, size.height * 0.7845618, size.width * 0.4059488, size.height * 0.7740603,
        size.width * 0.3974706, size.height * 0.7687147);
    path_0.cubicTo(size.width * 0.3911125, size.height * 0.7647059, size.width * 0.3841069, size.height * 0.7647059,
        size.width * 0.3700956, size.height * 0.7647059);
    path_0.lineTo(size.width * 0.1000000, size.height * 0.7647059);
    path_0.cubicTo(size.width * 0.05285956, size.height * 0.7647059, size.width * 0.02928931, size.height * 0.7647059,
        size.width * 0.01464469, size.height * 0.7302485);
    path_0.cubicTo(0, size.height * 0.6957897, 0, size.height * 0.6403309, 0, size.height * 0.5294118);
    path_0.lineTo(0, size.height * 0.2352941);
    path_0.cubicTo(
        0, size.height * 0.1243754, 0, size.height * 0.06891603, size.width * 0.01464469, size.height * 0.03445809);
    path_0.cubicTo(size.width * 0.02928931, 0, size.width * 0.05285956, 0, size.width * 0.1000000, 0);
    path_0.lineTo(size.width * 0.9000000, 0);
    path_0.cubicTo(
        size.width * 0.9471375, 0, size.width * 0.9707125, 0, size.width * 0.9853563, size.height * 0.03445809);
    path_0.cubicTo(
        size.width, size.height * 0.06891603, size.width, size.height * 0.1243754, size.width, size.height * 0.2352941);
    path_0.lineTo(size.width, size.height * 0.5294118);
    path_0.close();

    Paint paint0Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color(0xFFEEEEEE);

    canvas.drawPath(path_0, paint0Stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class PlayGameArrowBubleShape extends StatelessWidget {
  final String text;
  const PlayGameArrowBubleShape({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlayGameArrowCustomPainter(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 13),
        child: AppText(
          text: text,
          size: 20,
          fw: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlayGameArrowCustomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path_0 = Path();

    path_0.moveTo(size.width, size.height * 0.5294118);
    path_0.cubicTo(size.width, size.height * 0.6403309, size.width, size.height * 0.6957897, size.width * 0.9853563,
        size.height * 0.7302485);
    path_0.cubicTo(size.width * 0.9707125, size.height * 0.7647059, size.width * 0.9471375, size.height * 0.7647059,
        size.width * 0.9000000, size.height * 0.7647059);
    path_0.lineTo(size.width * 0.6299063, size.height * 0.7647059);
    path_0.cubicTo(size.width * 0.6158931, size.height * 0.7647059, size.width * 0.6088875, size.height * 0.7647059,
        size.width * 0.6025294, size.height * 0.7687147);
    path_0.cubicTo(size.width * 0.5940512, size.height * 0.7740603, size.width * 0.5863213, size.height * 0.7845618,
        size.width * 0.5801150, size.height * 0.7991632);
    path_0.cubicTo(size.width * 0.5754606, size.height * 0.8101162, size.width * 0.5719575, size.height * 0.8243912,
        size.width * 0.5649519, size.height * 0.8529412);
    path_0.lineTo(size.width * 0.5649519, size.height * 0.8529412);
    path_0.cubicTo(size.width * 0.5460525, size.height * 0.9299647, size.width * 0.5366025, size.height * 0.9684779,
        size.width * 0.5250000, size.height * 0.9842397);
    path_0.cubicTo(size.width * 0.5095300, size.height * 1.005254, size.width * 0.4904700, size.height * 1.005254,
        size.width * 0.4750000, size.height * 0.9842397);
    path_0.cubicTo(size.width * 0.4633975, size.height * 0.9684779, size.width * 0.4539475, size.height * 0.9299647,
        size.width * 0.4350481, size.height * 0.8529412);
    path_0.lineTo(size.width * 0.4350481, size.height * 0.8529412);
    path_0.cubicTo(size.width * 0.4280425, size.height * 0.8243912, size.width * 0.4245394, size.height * 0.8101162,
        size.width * 0.4198850, size.height * 0.7991632);
    path_0.cubicTo(size.width * 0.4136787, size.height * 0.7845618, size.width * 0.4059488, size.height * 0.7740603,
        size.width * 0.3974706, size.height * 0.7687147);
    path_0.cubicTo(size.width * 0.3911125, size.height * 0.7647059, size.width * 0.3841069, size.height * 0.7647059,
        size.width * 0.3700956, size.height * 0.7647059);
    path_0.lineTo(size.width * 0.1000000, size.height * 0.7647059);
    path_0.cubicTo(size.width * 0.05285956, size.height * 0.7647059, size.width * 0.02928931, size.height * 0.7647059,
        size.width * 0.01464469, size.height * 0.7302485);
    path_0.cubicTo(0, size.height * 0.6957897, 0, size.height * 0.6403309, 0, size.height * 0.5294118);
    path_0.lineTo(0, size.height * 0.2352941);
    path_0.cubicTo(
        0, size.height * 0.1243754, 0, size.height * 0.06891603, size.width * 0.01464469, size.height * 0.03445809);
    path_0.cubicTo(size.width * 0.02928931, 0, size.width * 0.05285956, 0, size.width * 0.1000000, 0);
    path_0.lineTo(size.width * 0.9000000, 0);
    path_0.cubicTo(
        size.width * 0.9471375, 0, size.width * 0.9707125, 0, size.width * 0.9853563, size.height * 0.03445809);
    path_0.cubicTo(
        size.width, size.height * 0.06891603, size.width, size.height * 0.1243754, size.width, size.height * 0.2352941);
    path_0.lineTo(size.width, size.height * 0.5294118);
    path_0.close();

    Paint paintFill = Paint()
      ..style = PaintingStyle.fill
      ..color = white;
    canvas.drawPath(path_0, paintFill);

    Paint paint0Stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = primary900;

    canvas.drawPath(path_0, paint0Stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
