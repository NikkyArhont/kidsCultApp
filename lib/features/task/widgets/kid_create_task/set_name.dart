import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

class KidCreateTaskSetName extends StatefulWidget {
  const KidCreateTaskSetName({super.key});

  @override
  State<KidCreateTaskSetName> createState() => _KidCreateTaskSetNameState();
}

class _KidCreateTaskSetNameState extends State<KidCreateTaskSetName> {
  final form = FormGroup({
    'name': FormControl<String>(
      validators: [
        Validators.required,
        Validators.minLength(3),
        Validators.maxLength(120),
      ],
    ),
    'description': FormControl<String>(),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidTaskCreateCubit, KidTaskCreateState>(
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
                              message: 'name_the_task_prompt'.tr(),
                              maskot: '2186-min',
                              flip: true,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ReactiveCustomInput(
                              formName: 'name',
                              label: 'title'.tr(),
                              hint: 'enter_title_hint'.tr(),
                              inputType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                              maxLenght: 120,
                              validationMessages: {
                                'required': (error) => 'field_required_error'.tr(),
                                'minLength': (error) => 'min_length_3'.tr(),
                                'maxLength': (error) => 'max_120_chars_error'.tr(),
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ReactiveCustomInput(
                              formName: 'description',
                              label: 'description_optional'.tr(),
                              hint: 'enter_description_hint'.tr(),
                              inputType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.newline,
                              minLines: 4,
                              maxLines: 5,
                              maxLenght: 500,
                              validationMessages: {
                                'minLength': (error) => 'min_length_3'.tr(),
                                'maxLength': (error) => 'max_500_chars_error'.tr(),
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
                                            final name = formGroup.control('name').value;
                                            final desc = formGroup.control('description').value;
                                            context.read<KidTaskCreateCubit>().onChangeNameAndDescription(name, desc);
                                            if (state.isEditMode) {
                                              context.read<KidTaskCreateCubit>().onChangeMode(false);
                                              context.read<KidTaskCreateCubit>().onJumpToPage(5);
                                            } else {
                                              context.read<KidTaskCreateCubit>().nextPage();
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
