import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MentorAppbarWidget extends StatelessWidget {
  final UserModel? selectedKid;

  const MentorAppbarWidget({super.key, this.selectedKid});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      width: double.infinity,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showKidSelectorModalBottomSheet(context);
            },
            child: CachedClickableImage(
              width: 48,
              height: 48,
              circularRadius: 100,
              imageUrl: selectedKid?.photo,
              noImageWidget: selectedKid == null ? Image.asset('assets/images/all_kids.png') : null,
            ),
          ),
          Expanded(
            child: AppText(
              text: 'tasks'.tr(),
              size: 24,
              fw: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ),
          if (selectedKid != null)
            Row(
              children: [
                SvgPicture.asset('assets/images/coin.svg'),
                 Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: AppText(
                    text: selectedKid!.points.toString(),
                    size: 20,
                    fw: FontWeight.bold,
                    color: dark5,
                  ),
                )
              ],
            )else const SizedBox(width: 40),
        ],
      ),
    );
  }
}
