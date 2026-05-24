import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';

class MaskotMessage extends StatelessWidget {
  final String maskot;
  final String message;
  final bool flip;
  final TextAlign align;
  const MaskotMessage({
    super.key,
    this.maskot = '2177-min',
    this.message = 'Default message',
    this.flip = false,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: flip
              ? Transform.flip(
                  flipX: true,
                  child: Image.asset(
                    'assets/images/$maskot.png',
                    fit: BoxFit.contain,
                  ),
                )
              : Image.asset(
                  'assets/images/$maskot.png',
                  fit: BoxFit.contain,
                ),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 3,
          child: LeftArrowBubleShape(
            child: AppText(
              text: message,
              size: 18,
              maxLine: 10,
              textAlign: align,
            ),
          ),
        ),
      ],
    );
  }
}
