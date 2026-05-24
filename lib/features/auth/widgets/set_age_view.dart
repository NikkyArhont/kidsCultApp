import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetAgeView extends StatelessWidget {
  const SetAgeView({super.key});

  void onDatePick(BuildContext context, {DateTime? birthDate}) async {
    final selectedDate = await showWheelDatePickerModalBottomSheet(context, selectedDate: birthDate);
    if (selectedDate != null && context.mounted) {
      context.read<FillDataCubit>().onChangeBirthDate(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FillDataCubit, FillDataState>(
      builder: (context, state) {
        final valid = state.birthDate != null;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'ageInputQuestion'.tr(),
                maskot: '2186-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomDateInput(
                  label: 'birthday'.tr(),
                  hint: 'selectDataHint'.tr(),
                  date: state.birthDate,
                  onTap: () => onDatePick(context, birthDate: state.birthDate),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledAppButton(
                      text: 'buttonNext'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          context.read<FillDataCubit>().nextPage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
