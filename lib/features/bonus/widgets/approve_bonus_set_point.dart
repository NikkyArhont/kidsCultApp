import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ApproveBonusSetPointScreen extends StatefulWidget {
  final BonusModel bonus;
  const ApproveBonusSetPointScreen({super.key, required this.bonus});

  @override
  State<ApproveBonusSetPointScreen> createState() => _ApproveBonusSetPointScreenState();
}

class _ApproveBonusSetPointScreenState extends State<ApproveBonusSetPointScreen> {
  final form = FormGroup({
    'point': FormControl<int>(
      validators: [Validators.required],
    ),
  });

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
      body: BlocConsumer<BonusCubit, BonusState>(
        listener: (context, state) {
          if (state.status == BonusStateStatus.approveError) {
            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
          } else if (state.status == BonusStateStatus.approveSuccess) {
            context.pop();
          }
        },
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
                                          text: 'apply'.tr(),
                                          isActive: valid,
                                          isLoading: state.status == BonusStateStatus.approving,
                                          onTap: () {
                                            formGroup.markAllAsTouched();
                                            if (valid) {
                                              final point = formGroup.control('point').value as int?;
                                              if (point == null) return;
                                              context.read<BonusCubit>().approveBonus(widget.bonus, point);
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
