import 'package:child_tracker/index.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

import 'package:qr_flutter/qr_flutter.dart';

class GenerateQrCard extends StatefulWidget {
  final String id;
  const GenerateQrCard({super.key, required this.id});

  @override
  State<GenerateQrCard> createState() => _GenerateQrCardState();
}

class _GenerateQrCardState extends State<GenerateQrCard> {
  bool generate = false;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width - 48;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Builder(builder: (context) {
        if (!generate) {
          return DottedBorder(
            borderPadding: const EdgeInsets.only(top: 0),
            borderType: BorderType.RRect,
            radius: const Radius.circular(20),
            color: greyscale300,
            dashPattern: const [8, 8],
            child: GestureDetector(
              onTap: () {
                setState(() {
                  generate = true;
                });
              },
              child: Container(
                width: width,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: greyscale50,
                ),
                child:  Center(
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.add, size: 32, color: primary900),
                    const SizedBox(height: 16),
                    AppText(text: 'generate'.tr(), size: 14, color: primary900),
                  ],
                )),
              ),
            ),
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: greyscale200),
                  ),
                  child: QrImageView(
                    key: ValueKey(widget.id),
                    data: widget.id,
                    padding: EdgeInsets.zero,
                    version: QrVersions.auto,
                    size: 270,
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
