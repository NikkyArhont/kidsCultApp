import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

class SetChatName extends StatelessWidget {
  const SetChatName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewChatCubit, NewChatState>(
      builder: (context, state) {
        return ReactiveForm(
          formGroup: FormGroup({
            'name': FormControl<String>(
              value: state.name,
              validators: [
                Validators.required,
                Validators.minLength(3),
                Validators.maxLength(60),
              ],
            ),
          }),
          child: Column(
            children: [
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: MaskotMessage(
                  message: 'how_to_name_chat'.tr(),
                  maskot: '2186-min',
                  flip: true,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ReactiveCustomInput(
                  formName: 'name',
                  label: 'name'.tr(),
                  hint: 'enter_name'.tr(),
                  inputType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLenght: 60,
                  validationMessages: {
                    'required': (error) => 'fill_field'.tr(),
                    'minLength': (error) => 'min_length_3'.tr(),
                    'maxLength': (error) => 'max_length_60'.tr(),
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
                            text: 'next'.tr(),
                            isActive: valid,
                            isLoading: state.status == NewChatStatus.loading,
                            onTap: () {
                              if (valid) {
                                if(state.status == NewChatStatus.loading) return;
                                context.read<NewChatCubit>().onChangeName(formGroup.control('name').value);
                                context.read<NewChatCubit>().nextPage();
                              } else {
                                formGroup.markAllAsTouched();
                                print(formGroup.errors);
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
        );
      },
    );
  }
}
