// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:child_tracker/features/profile/controllers/profile/profile_cubit.dart';
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reactive_forms/reactive_forms.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = FormGroup(
    {
      'name': FormControl<String>(
        validators: [
          Validators.required,
          Validators.minLength(3),
          Validators.maxLength(60),
          Validators.pattern(r'^[a-zA-Zа-яА-ЯёЁ\s]+$'),
        ],
      ),
    },
  );
  String? city;
  XFile? selectedFile;
  DateTime? birthDate;
  String? birthDateError;

  void onSaveTap(BuildContext context) {
    final me = context.read<UserCubit>().state;
    form.markAllAsTouched();

    if (form.valid) {
      if (birthDate == null && (me?.isKid ?? true)) {
        setState(() {
          birthDateError = 'fill_field'.tr();
        });
        return;
      }
      Map<String, dynamic> newForm = form.value.map((key, value) => MapEntry(key, value.toString()));
      newForm['city'] = city;
      newForm['birth_date'] = birthDate;
      context.read<ProfileCubit>().updateProfile(newForm, selectedFile);
    }
  }

  void onPick() async {
    final XFile? xfile = await CustomImagePicker.pickAvatarFromGallery(context);

    if (xfile == null) return;

    setState(() {
      selectedFile = xfile;
    });
  }

  void init() {
    final user = context.read<UserCubit>().state;
    if (user == null) return;
    if (user.isKid) {
      form.value = {'name': user.name};
      birthDate = user.birthDate;
      city = user.city;
    } else {
      form.value = {'name': user.name};
    }
  }

  @override
  void initState() {
    init();
    super.initState();
  }

  void onSetCity(String city) => setState(() => this.city = city);

  void onDatePick(BuildContext context) async {
    final selectedDate = await showWheelDatePickerModalBottomSheet(context, selectedDate: birthDate);
    if (selectedDate != null && context.mounted) {
      setState(() => birthDate = selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit(userCubit: sl()),
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStateStatus.error) {
            SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
          } else if (state.status == ProfileStateStatus.success) {
            SnackBarSerive.showSuccessSnackBar('profile_updated'.tr());
            context.pop();
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leadingWidth: 70,
              leading: IconButton(
                icon: const Icon(CupertinoIcons.arrow_left),
                onPressed: () => context.pop(),
              ),
              title: AppText(text: 'profileData'.tr(), size: 24, fw: FontWeight.w700),
              centerTitle: true,
            ),
            body: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: LayoutBuilder(builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).viewInsets.bottom + 0.0
                            : 0.0,
                      ),
                      child: IntrinsicHeight(
                        child: ReactiveForm(
                          formGroup: form,
                          child: Column(
                            children: [
                              const SizedBox(height: 24),
                              CachedClickableImage(
                                circularRadius: 100,
                                height: 120,
                                width: 120,
                                imageFile: selectedFile?.path != null ? File(selectedFile!.path) : null,
                                imageUrl: context.read<UserCubit>().state?.photo,
                                onTap: onPick,
                              ),
                              const SizedBox(height: 44),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: ReactiveCustomInput(
                                  formName: 'name',
                                  label: 'nameInputPlaceholder'.tr(),
                                  hint: 'nameInputHint'.tr(),
                                  inputType: TextInputType.text,
                                  textCapitalization: TextCapitalization.sentences,
                                  textInputAction: TextInputAction.next,
                                  validationMessages: {
                                    'required': (error) => 'fill_field'.tr(),
                                    'minLength': (error) => 'min_length_3'.tr(),
                                    'maxLength': (error) => 'max_length_60'.tr(),
                                    'pattern': (error) => 'invalid_characters'.tr(),
                                  },
                                ),
                              ),
                              BlocBuilder<UserCubit, UserModel?>(
                                builder: (context, user) {
                                  if (user == null) return const SizedBox();
                                  if (user.isKid) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 28),
                                          CustomDateInput(
                                            label: 'birthday'.tr(),
                                            hint: 'selectDataHint'.tr(),
                                            date: birthDate,
                                            onTap: () => onDatePick(context),
                                            errorText: birthDateError,
                                          ),
                                          const SizedBox(height: 28),
                                          AppText(text: 'cityInputPlaceholder'.tr()),
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () {
                                              context.push('/city_search', extra: onSetCity as Function(String));
                                            },
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                              decoration: BoxDecoration(
                                                color: greyscale50,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: AppText(
                                                text: city != null ? city! : 'cityInputEnter'.tr(),
                                                fw: city != null ? FontWeight.w600 : FontWeight.normal,
                                                color: city != null ? greyscale900 : greyscale500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                              const Spacer(),
                              Container(
                                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      FilledDestructiveAppButton(
                                        onTap: () => showLogoutDialog(context),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/logout.svg',
                                              width: 20,
                                              height: 20,
                                              color: error,
                                            ),
                                            const SizedBox(width: 20),
                                            AppText(text: 'signOutButton'.tr(), color: error, fw: FontWeight.w700),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      FilledDestructiveAppButton(
                                        onTap: () => showDeleteAccountDialog(context),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/images/delete.svg',
                                              width: 20,
                                              height: 20,
                                              color: error,
                                            ),
                                            const SizedBox(width: 20),
                                            AppText(
                                                text: 'confirmDeleteAccountTitle'.tr(),
                                                color: error,
                                                fw: FontWeight.w700),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ReactiveFormConsumer(
                                        builder: (context, formGroup, child) {
                                          return FilledAppButton(
                                            text: 'apply'.tr(),
                                            onTap: () =>
                                                state.status == ProfileStateStatus.saving ? null : onSaveTap(context),
                                            isLoading: state.status == ProfileStateStatus.saving,
                                            isActive: formGroup.valid,
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
