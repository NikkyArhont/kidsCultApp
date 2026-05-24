import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

class CreateBonusSetPoint extends StatefulWidget {
  final bool isKidBonus;
  const CreateBonusSetPoint({super.key, required this.isKidBonus});

  @override
  State<CreateBonusSetPoint> createState() => _CreateBonusSetPointState();
}

class _CreateBonusSetPointState extends State<CreateBonusSetPoint> {
  final form = FormGroup({
    'point': FormControl<int>(
      validators: [
        Validators.required,
      ],
    ),
  });

  @override
  void initState() {
    super.initState();
    final oldPoint = context.read<CreateBonusCubit>().state.point;
    if (oldPoint != null) {
      form.value = {'point': oldPoint};
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateBonusCubit, CreateBonusState>(
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: IntrinsicHeight(
                    child: ReactiveForm(
                      formGroup: form,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: MaskotMessage(
                              message: 'bonus_condition'.tr(),
                              maskot: '2186-min',
                              flip: true,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ReactiveCustomInput(
                              formName: 'point',
                              label: 'bonus_count'.tr(),
                              hint: 'enter'.tr(),
                              inputType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textInputAction: TextInputAction.next,
                              validationMessages: {
                                'required': (error) => 'field_required_error'.tr(),
                              },
                            ),
                          ),
                          const Spacer(),
                          ReactiveFormConsumer(
                            builder: (context, formGroup, child) {
                              final valid = formGroup.valid;
                              return Container(
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: FilledAppButton(
                                        text: state.isEditMode ? 'apply'.tr() : 'next'.tr(),
                                        isActive: valid,
                                        onTap: () {
                                          formGroup.markAllAsTouched();
                                          if (valid) {
                                            final point = formGroup.control('point').value as int?;
                                            if (point == null) return;
                                            context.read<CreateBonusCubit>().onChangePoint(point);
                                            FocusManager.instance.primaryFocus?.unfocus();
                                            if (state.isEditMode) {
                                              context.read<CreateBonusCubit>().onChangeMode(false);
                                              context.read<CreateBonusCubit>().onJumpToPage(widget.isKidBonus ? 4 : 5);
                                            } else {
                                              context.read<CreateBonusCubit>().nextPage();
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
