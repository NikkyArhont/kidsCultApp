import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';

Future<ImageSource?> showImageSourceSelectModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: greyscale200,
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
             AppText(
              text: 'uploadPhoto'.tr(),
              size: 24,
              fw: FontWeight.w700,
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildIconButton(
                  icon: 'picker_gallery',
                  label: 'gallery'.tr(),
                  onPressed: () {
                    Navigator.pop(context, ImageSource.gallery);
                  },
                ),
                const SizedBox(width: 40),
                _buildIconButton(
                  icon: 'picker_camera',
                  label: 'camera'.tr(),
                  onPressed: () {
                    Navigator.pop(context, ImageSource.camera);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
          ],
        ),
      );
    },
  );
}

Widget _buildIconButton({
  required String icon,
  required String label,
  required VoidCallback onPressed,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE4E7FF)),
          child: Center(
            child: SvgPicture.asset('assets/images/$icon.svg'),
          ),
        ),
      ),
      const SizedBox(height: 16),
      AppText(text: label),
    ],
  );
}
