import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

class CreateBonusSetLink extends StatefulWidget {
  final bool isKidBonus;
  const CreateBonusSetLink({super.key, required this.isKidBonus});

  @override
  State<CreateBonusSetLink> createState() => _CreateBonusSetLinkState();
}

class _CreateBonusSetLinkState extends State<CreateBonusSetLink> {
  final form = FormGroup({
    'link': FormControl<String>(
      validators: [
        Validators.pattern(urlRegExp),
      ],
    ),
  });

  @override
  void initState() {
    super.initState();
    final oldLink = context.read<CreateBonusCubit>().state.link;
    form.value = {'link': oldLink};
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
                              message: 'add_link'.tr(),
                              maskot: '2185-min',
                              flip: false,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: ReactiveCustomInput(
                              formName: 'link',
                              label: 'link'.tr(),
                              hint: 'put'.tr(),
                              inputType: TextInputType.url,
                              textCapitalization: TextCapitalization.none,
                              maxLenght: 300,
                              validationMessages: {
                                'pattern': (error) => 'invalid_url'.tr(),
                              },
                            ),
                          ),
                          const Spacer(),
                          ReactiveFormConsumer(
                            builder: (context, formGroup, child) {
                              final link = formGroup.control('link').value as String?;
                              final valid = link != null && link.isNotEmpty;
                              return Container(
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 20),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: FilledSecondaryAppButton(
                                              text: 'skip'.tr(),
                                              onTap: () {
                                                context.read<CreateBonusCubit>().onChangeLink('');
                                                FocusManager.instance.primaryFocus?.unfocus();
                                                if (state.isEditMode) {
                                                  context.read<CreateBonusCubit>().onChangeMode(false);
                                                  context.read<CreateBonusCubit>().onJumpToPage(5);
                                                } else {
                                                  context.read<CreateBonusCubit>().nextPage();
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 24),
                                          Expanded(
                                            child: FilledAppButton(
                                              text: state.isEditMode ? 'apply'.tr() : 'next'.tr(),
                                              isActive: valid,
                                              onTap: () {
                                                formGroup.markAllAsTouched();
                                                if (valid) {
                                                  context.read<CreateBonusCubit>().onChangeLink(link);
                                                  FocusManager.instance.primaryFocus?.unfocus();
                                                  if (state.isEditMode) {
                                                    context.read<CreateBonusCubit>().onChangeMode(false);
                                                    context
                                                        .read<CreateBonusCubit>()
                                                        .onJumpToPage(widget.isKidBonus ? 4 : 5);
                                                  } else {
                                                    context.read<CreateBonusCubit>().nextPage();
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ],
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
