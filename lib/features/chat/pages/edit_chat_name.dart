import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class EditChatNameScreen extends StatefulWidget {
  final ChatModel chat;
  const EditChatNameScreen({super.key, required this.chat});

  @override
  State<EditChatNameScreen> createState() => _EditChatNameScreenState();
}

class _EditChatNameScreenState extends State<EditChatNameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title:  AppText(
          text: 'chat_name'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: ReactiveForm(
        formGroup: FormGroup({
          'name': FormControl<String>(
            value: widget.chat.name,
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
                          text: 'save'.tr(),
                          isActive: valid,
                          onTap: () async {
                            if (valid) {
                              await widget.chat.ref.update({'name': formGroup.control('name').value});
                              if (mounted) {
                                setState(() {
                                  widget.chat.name = formGroup.control('name').value;
                                });

                                SnackBarSerive.showSuccessSnackBar('name_updated'.tr());
                                if (context.mounted) context.pop();
                              }
                            } else {
                              formGroup.markAllAsTouched();
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
    );
  }
}
