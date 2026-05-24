import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class MentorTaskEditPointScreen extends StatefulWidget {
  const MentorTaskEditPointScreen({super.key});

  @override
  State<MentorTaskEditPointScreen> createState() => _MentorTaskEditPointScreenState();
}

class _MentorTaskEditPointScreenState extends State<MentorTaskEditPointScreen> {
  final form = FormGroup({
    'point': FormControl<int>(
      validators: [
        Validators.min(1),
        Validators.max(10),
      ],
    ),
  });

  @override
  void initState() {
    final state = context.read<MentorTaskEditCubit>().state;
    form.control('point').value = state.point;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: BlocBuilder<MentorTaskEditCubit, MentorTaskEditState>(
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
                                message: 'assign_point_to_task?'.tr(),
                                maskot: '2186-min',
                                flip: true,
                              ),
                            ),
                            const SizedBox(height: 40),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: AppText(
                                text: 'assign_point_to_task_desc'.tr(),
                                maxLine: 3,
                                textAlign: TextAlign.center,
                                size: 18,
                                fw: FontWeight.w400,
                                color: greyscale700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: ReactiveCustomInput(
                                formName: 'point',
                                label: '${'pointCountMax'.tr()}10)',
                                hint: 'cityInputEnter'.tr(),
                                inputType: TextInputType.number,
                                textCapitalization: TextCapitalization.none,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                validationMessages: {
                                  'required': (error) => 'field_required_error'.tr(),
                                  'min': (error) => 'min_1'.tr(),
                                  'max': (error) => 'max_10'.tr(),
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
                                          text: 'apply'.tr(),
                                          isActive: valid,
                                          onTap: () {
                                            formGroup.markAllAsTouched();
                                            if (valid) {
                                              final points = formGroup.control('point').value as int?;

                                              context.read<MentorTaskEditCubit>().onChangePoint(points ?? 0);
                                              context.pop();
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
      ),
    );
  }
}
