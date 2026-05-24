import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KidBonusAppBarWidget extends StatelessWidget {
  final UserModel? selectedMentor;
  final UserModel me;
  const KidBonusAppBarWidget({super.key, required this.me, this.selectedMentor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      width: double.infinity,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              showBonusMentorSelectorModalBottomSheet(context);
            },
            child: CachedClickableImage(
              width: 48,
              height: 48,
              circularRadius: 100,
              imageUrl: selectedMentor?.photo,
              noImageWidget: selectedMentor == null ? Image.asset('assets/images/mentors.png') : null,
            ),
          ),
          Expanded(
            child: AppText(
              text: 'bonuses'.tr(),
              size: 24,
              fw: FontWeight.bold,
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            children: [
              SvgPicture.asset('assets/images/coin.svg'),
              Padding(
                padding: const EdgeInsets.only(left: 5),
                child: AppText(
                  text: me.points.toString(),
                  size: 20,
                  fw: FontWeight.bold,
                  color: dark5,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}
