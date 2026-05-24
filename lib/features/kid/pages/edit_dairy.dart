import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class EditDairyScreen extends StatefulWidget {
  final DairyModel dairy;
  const EditDairyScreen({super.key, required this.dairy});

  @override
  State<EditDairyScreen> createState() => _EditDairyScreenState();
}

class _EditDairyScreenState extends State<EditDairyScreen> {
  DairyEmotion? selectedEmotion;
  final form = FormGroup({
    'text': FormControl<String>(validators: [
      Validators.required,
      Validators.maxLength(300),
      Validators.minLength(3),
    ]),
  });
  late DateTime selectedDate;

  @override
  void initState() {
    selectedDate = widget.dairy.time ?? DateTime.now();
    selectedEmotion = widget.dairy.emotion;
    form.value = {'text': widget.dairy.text};
    super.initState();
  }

  void onSubmit() async {
    final valid = form.valid && selectedEmotion != null;
    if (valid) {
      final DateTime now = DateTime.now();
      final finalDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, now.hour, now.minute);
      context.read<DairyCubit>().editDairy(
            widget.dairy,
            form.value['text'] as String,
            selectedEmotion!,
            finalDate,
          );
    }
  }

  void onDelete() async {
    final bool confirm = await showConfirmModalBottomSheet(
          context,
          confirmText: 'yes_delete'.tr(),
          title: 'delete'.tr(),
          message: 'are_you_sure_delete'.tr(),
          isDestructive: true,
          cancelText: 'cancel'.tr(),
        ) ??
        false;

    if (confirm && mounted) {
      await context.read<DairyCubit>().deleteDairy(widget.dairy);
      SnackBarSerive.showSuccessSnackBar('review_deleted'.tr());
      if (mounted) context.pop();
    }
  }

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: SvgPicture.asset(
                'assets/images/delete.svg',
                width: 28,
                height: 28,
                fit: BoxFit.contain,
              ),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
      body: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          return Column(
            children: [
              FutureBuilder<List<DairyModel>>(
                future: _future(me.ref),
                builder: (context, snapshot) {
                  return CustomDairyCalendar(
                    dairies: snapshot.data ?? [],
                    selectedDay: selectedDate,
                    onDaySelected: (s) {
                      setState(() {
                        selectedDate = s;
                      });
                    },
                  );
                },
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: ReactiveForm(
                    formGroup: form,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Padding(
                              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                              child: IntrinsicHeight(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 40, right: 24, top: 16),
                                      child: MaskotMessage(
                                        maskot: '2185-min',
                                        message: 'how_was_your_day'.tr(),
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    Container(
                                      width: double.infinity,
                                      height: 76,
                                      margin: const EdgeInsets.symmetric(horizontal: 24),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: greyscale200, width: 3),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              selectedEmotion = DairyEmotion.bad;
                                            }),
                                            child: _EmotionIcon(
                                              emotion: DairyEmotion.bad,
                                              isSelected: selectedEmotion == DairyEmotion.bad,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              selectedEmotion = DairyEmotion.sad;
                                            }),
                                            child: _EmotionIcon(
                                              emotion: DairyEmotion.sad,
                                              isSelected: selectedEmotion == DairyEmotion.sad,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              selectedEmotion = DairyEmotion.normal;
                                            }),
                                            child: _EmotionIcon(
                                              emotion: DairyEmotion.normal,
                                              isSelected: selectedEmotion == DairyEmotion.normal,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              selectedEmotion = DairyEmotion.good;
                                            }),
                                            child: _EmotionIcon(
                                              emotion: DairyEmotion.good,
                                              isSelected: selectedEmotion == DairyEmotion.good,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => setState(() {
                                              selectedEmotion = DairyEmotion.joyful;
                                            }),
                                            child: _EmotionIcon(
                                              emotion: DairyEmotion.joyful,
                                              isSelected: selectedEmotion == DairyEmotion.joyful,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: ReactiveCustomInput(
                                        formName: 'text',
                                        label: 'review'.tr(),
                                        hint: 'tell_about_your_day'.tr(),
                                        maxLines: 6,
                                        minLines: 5,
                                        validationMessages: {
                                          'required': (error) => 'fill_field'.tr(),
                                          'minLength': (error) => 'min_length_3'.tr(),
                                        },
                                      ),
                                    ),
                                    const Spacer(),
                                    const Divider(height: 1, thickness: 1, color: greyscale200),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: BlocConsumer<DairyCubit, DairyState>(
                                        listener: (context, state) {
                                          if (state.status == DairyStateStatus.editSuccess) {
                                            context.pop();
                                            SnackBarSerive.showSuccessSnackBar('review_updated'.tr());
                                          } else if (state.status == DairyStateStatus.editError) {
                                            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
                                          }
                                        },
                                        builder: (context, state) {
                                          return ReactiveFormConsumer(
                                            builder: (context, formGroup, child) {
                                              final valid = formGroup.valid && selectedEmotion != null;
                                              return FilledAppButton(
                                                text: 'apply'.tr(),
                                                onTap: state.status == DairyStateStatus.editing ? null : onSubmit,
                                                isActive: valid,
                                                isLoading: state.status == DairyStateStatus.editing,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EmotionIcon extends StatelessWidget {
  final DairyEmotion emotion;
  final bool isSelected;
  const _EmotionIcon({required this.emotion, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/${dairyEmotionIcon(emotion, filled: isSelected)}.svg',
      height: 44,
      width: 44,
    );
  }
}

Future<List<DairyModel>> _future(DocumentReference kidRef) async {
  final query = DairyModel.collection.where('kid', isEqualTo: kidRef).orderBy('created_at', descending: true);

  return query.get().then((event) => event.docs.map((e) => DairyModel.fromFirestore(e)).toList());
}
