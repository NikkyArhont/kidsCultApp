
import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BonusChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final BonusChip chip;
  const BonusChipWidget({super.key, required this.label, required this.selected, required this.chip});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BonusCubit>().onChipSelected(chip),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: selected ? primary900 : null,
          borderRadius: BorderRadius.circular(100),
          border: selected ? null : Border.all(color: primary900, width: 1.5),
        ),
        child: Center(
          child: AppText(
            text: label,
            size: 14,
            color: selected ? white : primary900,
          ),
        ),
      ),
    );
  }
}
