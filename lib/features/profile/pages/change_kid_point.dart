import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ChangeKidPointScreen extends StatefulWidget {
  final UserModel kid;
  final bool isIncrease;
  const ChangeKidPointScreen({super.key, required this.kid, required this.isIncrease});

  @override
  State<ChangeKidPointScreen> createState() => _ChangeKidPointScreenState();
}

class _ChangeKidPointScreenState extends State<ChangeKidPointScreen> {
  bool loading = false;
  bool determineLoading = false;
  int maxAmount = 0;
  final form = FormGroup({
    'text': FormControl<String>(
      validators: [
        Validators.maxLength(300),
        Validators.minLength(3),
      ],
    ),
    'amount': FormControl<int>(
      validators: [
        Validators.required,
        Validators.min(1),
      ],
    ),
  });

  void onSubmit() async {
    final valid = form.valid;
    if (valid) {
      int? amount = form.control('amount').value as int?;

      if (amount == null) {
        SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
        return;
      }

      if(amount == 0) {
        form.control('amount').setErrors({'min': true});
        return;
      }

      if (!widget.isIncrease) {
        amount = -amount;
      }

      final fcm = sl<FirebaseMessaginService>();

      final mentor = context.read<UserCubit>().state;

      if (mentor == null) {
        SnackBarSerive.showErrorSnackBar('defaultErrorText'.tr());
        return;
      }

      final doc = {
        'kid': widget.kid.ref,
        'mentor': mentor.ref,
        'created_at': FieldValue.serverTimestamp(),
        'coin': amount,
        'name': form.control('text').value,
      };

      print('doc: $doc');

      try {
        setState(() {
          loading = true;
        });

        final ref = CoinChangeModel.collection.doc();
        await ref.set(doc);

        if (mounted) await widget.kid.ref.update({'points': FieldValue.increment(amount)});

        fcm.sendPushToKidOnCoinChanged(mentor, widget.kid.ref, amount);

        if (mounted) {
          setState(() {
            loading = false;
          });

          context.replace('/kid_coins/success', extra: {
            'kidName': widget.kid.name,
            'amount': amount,
          });
        }
      } catch (e) {
        print('Error while changing kid point: $e');
        SnackBarSerive.showErrorSnackBar(e.toString());
        if (mounted) {
          setState(() {
            loading = false;
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (!widget.isIncrease) _determineMaxAmount();
  }

  void onInfoTap() {
    showCoinChangeInfoModalBottomSheet(context, 50);
  }

  void _determineMaxAmount() async {
    final me = context.read<UserCubit>().state;
    if (me == null) return;
    try {
      setState(() {
        determineLoading = true;
      });

      final List<CoinChangeModel> snap = await CoinChangeModel.collection
          .where('kid', isEqualTo: widget.kid.ref)
          .where('mentor', isEqualTo: me.ref)
          .get()
          .then((value) => value.docs.map((e) => CoinChangeModel.fromFirestore(e)).toList());

      int totalCoins = snap.isEmpty ? 0 : snap.fold(0, (total, item) => total + item.coin);

      if (mounted) {
        final control = form.control('amount');
        control.setValidators([
          Validators.required,
          Validators.max(totalCoins),
        ]);

        setState(() {
          maxAmount = totalCoins;
          determineLoading = false;
        });
      }
    } catch (e) {
      print('Error {_determineMaxAmount}: $e');
      if (mounted) {
        setState(() {
          determineLoading = false;
        });
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) return const SizedBox();
        return Scaffold(
          backgroundColor: white,
          appBar: AppBar(
            leadingWidth: 70,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.arrow_left),
              onPressed: () => context.pop(),
            ),
            title: AppText(
              text: widget.isIncrease ? 'increase'.tr() : 'decrease'.tr(),
              size: 24,
              fw: FontWeight.w700,
            ),
            centerTitle: true,
          ),
          body: determineLoading
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
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
                                        maskot: '2186-min',
                                        message: widget.isIncrease ? 'howMuchIncrease'.tr() : 'howMuchDecrease'.tr(),
                                        flip: true,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              AppText(
                                                text: widget.isIncrease
                                                    ? 'pointCount'.tr()
                                                    : '${'pointCountMax'.tr()}$maxAmount)',
                                              ),
                                              if (!widget.isIncrease)
                                                GestureDetector(
                                                  onTap: onInfoTap,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 12),
                                                    child: SvgPicture.asset(
                                                      'assets/images/info_square.svg',
                                                      width: 16,
                                                      height: 16,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ReactiveCustomInput(
                                            formName: 'amount',
                                            label: '',
                                            hint: 'cityInputEnter'.tr(),
                                            inputType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter.digitsOnly,
                                            ],
                                            validationMessages: {
                                              'required': (_) => 'fill_field'.tr(),
                                              'min': (_) => 'min1'.tr(),
                                              'max': (_) => 'maxAmountError'.tr(),
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: ReactiveCustomInput(
                                        formName: 'text',
                                        label: 'optionalCouse'.tr(),
                                        hint: 'cityInputEnter'.tr(),
                                        inputType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                        maxLines: 6,
                                        minLines: 5,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Divider(height: 1, thickness: 1, color: greyscale200),
                                    const SizedBox(height: 24),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: ReactiveFormConsumer(
                                        builder: (context, formGroup, child) {
                                          final valid = formGroup.valid;
                                          return FilledAppButton(
                                            onTap: loading ? null : onSubmit,
                                            text: 'buttonNext'.tr(),
                                            isActive: valid,
                                            isLoading: loading,
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
        );
      },
    );
  }
}
