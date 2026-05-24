import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BonusEditNameScreen extends StatefulWidget {
  const BonusEditNameScreen({super.key});

  @override
  State<BonusEditNameScreen> createState() => _BonusEditNameScreenState();
}

class _BonusEditNameScreenState extends State<BonusEditNameScreen> {
  final form = FormGroup({
    'name': FormControl<String>(
      validators: [
        Validators.required,
        Validators.minLength(3),
        Validators.maxLength(120),
      ],
    ),
  });

  @override
  void initState() {
    init();
    super.initState();
  }

  void init() {
    final state = context.read<EditBonusCubit>().state;
    form.value = {'name': state.name};
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
      body: BlocBuilder<EditBonusCubit, EditBonusState>(
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
                                hint: 'enter_name'.tr(),
                                inputType: TextInputType.text,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.next,
                                maxLenght: 120,
                                validationMessages: {
                                  'required': (error) => 'fill_field'.tr(),
                                  'minLength': (error) => 'min_length_3'.tr(),
                                  'maxLength': (error) => 'max_120_chars_error'.tr(),
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
                                              final name = formGroup.control('name').value;
                                              context.read<EditBonusCubit>().onChangeName(name);
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
