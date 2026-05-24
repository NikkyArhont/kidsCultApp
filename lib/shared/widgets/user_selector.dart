import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserSelector extends StatelessWidget {
  final bool isSelected;
  final String? image;
  final String name;
  final Widget? placeholder;
  final double radius;
  final VoidCallback onTap;
  const UserSelector({
    super.key,
    this.isSelected = false,
    this.image,
    this.name = '-',
    this.placeholder,
    this.radius = 100,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primary900 : greyscale200, width: 3),
        ),
        child: Row(
          children: [
            CachedClickableImage(
              width: 60,
              height: 60,
              circularRadius: radius,
              imageUrl: image,
              noImageWidget: placeholder,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(text: name, size: 20),
            ),
            if (isSelected)
              Padding(padding: const EdgeInsets.only(left: 10), child: SvgPicture.asset('assets/images/checkmark.svg')),
          ],
        ),
      ),
    );
  }
}
