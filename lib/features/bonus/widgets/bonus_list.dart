import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class BonusListWidget extends StatelessWidget {
  final List<BonusModel> bonuses;
  final BonusChip selectedChip;
  final UserModel me;

  const BonusListWidget({
    super.key,
    required this.bonuses,
    required this.selectedChip,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 12, 24),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: BonusChip.values
                .map((e) => BonusChipWidget(
                      label: bonusChipRusName(e),
                      chip: e,
                      selected: selectedChip == e,
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: Builder(builder: (context) {
            final bonusesCopy = List.of(bonuses);
            late List<BonusModel> result;
            if (selectedChip == BonusChip.request) {
              result = bonusesCopy.where((bonus) => bonus.status == BonusStatus.needApprove).toList();
            } else if (selectedChip == BonusChip.active) {
              result = bonusesCopy.where((bonus) => bonus.status == BonusStatus.active || bonus.status == BonusStatus.readyToReceive).toList();
            } else if (selectedChip == BonusChip.received) {
              result = bonusesCopy.where((bonus) => bonus.status == BonusStatus.received).toList();
            } else if (selectedChip == BonusChip.canceled) {
              result = bonusesCopy.where((bonus) => bonus.status == BonusStatus.canceled).toList();
            } else if (selectedChip == BonusChip.rejected) {
              result = bonusesCopy.where((bonus) => bonus.status == BonusStatus.rejected).toList();
            } else {
              result = bonusesCopy;
            }

            if (result.isEmpty) {
              return const BonusEmptyWidget();
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: result.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => BonusCard(bonus: result[index], me: me),
            );
          }),
        ),
      ],
    );
  }
}
