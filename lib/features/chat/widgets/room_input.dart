// ignore_for_file: deprecated_member_use

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RoomInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final void Function(String) onSend;
  const RoomInputWidget({super.key, required this.controller, required this.onSend});

  @override
  State<RoomInputWidget> createState() => _RoomInputWidgetState();
}

class _RoomInputWidgetState extends State<RoomInputWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: greyscale100)),
        color: white,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              style: const TextStyle(
                fontSize: 18,
                color: greyscale900,
                fontWeight: FontWeight.w600,
                fontFamily: Involve,
                height: 1.6,
              ),
              minLines: 1,
              maxLines: 5,
              maxLength: 500,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: greyscale50,
                hintText: '${"cityInputEnter".tr()} ...',
                counterText: '',
                hintStyle: const TextStyle(
                  fontSize: 18,
                  color: greyscale500,
                  fontWeight: FontWeight.normal,
                  fontFamily: Involve,
                  height: 1.6,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, child) {
                final hasText = value.text.trim().isNotEmpty;
                return GestureDetector(
                  onTap: () {
                    if (hasText) {
                      widget.onSend(widget.controller.text);
                      setState(() {
                        widget.controller.clear();
                      });
                    }
                  },
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: hasText ? primary900 : const Color(0xFFACB3E5),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/send.svg',
                        width: 28,
                        height: 28,
                        color: white,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              }),
        ],
      ),
    );
  }
}
