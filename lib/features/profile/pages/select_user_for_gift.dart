import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class SelectUserForGiftScreen extends StatefulWidget {
  const SelectUserForGiftScreen({super.key});

  @override
  State<SelectUserForGiftScreen> createState() => _SelectUserForGiftScreenState();
}

class _SelectUserForGiftScreenState extends State<SelectUserForGiftScreen> {
  final form = FormGroup({
    'phone': FormControl<String>(
      validators: [Validators.required],
    ),
  });
  String? error;
  bool loading = false;

  final service = sl<PaymentService>();

  var phoneFormatter = MaskTextInputFormatter(
    mask: '+###############',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  void onTap() async {
    if (form.valid) {
      FocusManager.instance.primaryFocus?.unfocus();
      final phone = phoneFormatter.getUnmaskedText();
      print(phone);
      setState(() {
        loading = true;
        error = null;
      });
      final UserModel? user = await service.findUserForGift(phone);
      if (user == null) {
        error = 'mentor_not_found'.tr();
      } else if (user.isKid) {
        error = 'mentor_not_found'.tr();
      }
      setState(() {
        loading = false;
      });

      if (user != null && (!user.isKid) && mounted) {
        context.pop(user);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'phoneNumberLabel'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: ReactiveForm(
          formGroup: form,
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom > 0
                        ? MediaQuery.of(context).viewInsets.bottom + 16.0
                        : 16.0,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          child: AppText(
                            text: 'input_phone_of_mentor'.tr(),
                            fw: FontWeight.w400,
                            color: greyscale700,
                            textAlign: TextAlign.center,
                            maxLine: 3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ReactiveCustomInput(
                            formName: 'phone',
                            label: 'phoneNumberLabel'.tr(),
                            hint: 'enterNumberHint'.tr(),
                            textInputAction: TextInputAction.done,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, phoneFormatter],
                            inputType: TextInputType.number,
                            validationMessages: {
                              'required': (error) => 'phoneRequiredError'.tr(),
                              'invalid': (error) => 'phoneInvalidError'.tr(),
                            },
                          ),
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CustomErrorWidget(errorText: error),
                          ),
                        const Spacer(),
                        Container(
                          decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              ReactiveFormConsumer(builder: (context, formGroup, child) {
                                final valid = formGroup.valid;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: FilledAppButton(
                                    text: 'buttonNext'.tr(),
                                    isActive: valid,
                                    onTap: onTap,
                                    isLoading: loading,
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
