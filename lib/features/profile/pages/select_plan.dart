import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class SelectPlanScreen extends StatefulWidget {
  const SelectPlanScreen({super.key});

  @override
  State<SelectPlanScreen> createState() => _SelectPlanScreenState();
}

class _SelectPlanScreenState extends State<SelectPlanScreen> {
  final paymentService = sl<PaymentService>();
  bool loading = true;
  bool isCheckboxActive = false;
  List<SubscriptionModel> plans = [];
  SubscriptionModel? selectedPlan;

  void onTapPurchase() {
    context.pop(selectedPlan);
  }

  void getPlans() async {
    try {
      List<SubscriptionModel> result = await paymentService.getTariffs();
      if (mounted) {
        setState(() {
          plans = result;
          loading = false;
        });
      }
    } catch (e) {
      SnackBarSerive.showErrorSnackBar(e.toString());
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getPlans();
  }

  @override
  Widget build(BuildContext context) {
    bool isActiveBtn = isCheckboxActive && selectedPlan != null;
    return Scaffold(
      backgroundColor: greyscale100,
      appBar: AppBar(
        backgroundColor: greyscale100,
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'yourPlan'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [...plans.map((plan) => planCard(plan, plan.id == selectedPlan?.id))],
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            color: white,
            child: Column(
              children: [
                checkbox(),
                const SizedBox(height: 24),
                FilledAppButton(
                  text: 'subscribe'.tr(),
                  onTap: isActiveBtn ? onTapPurchase : null,
                  isActive: isActiveBtn,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget checkbox() {
    return Row(
      children: [
        Transform.scale(
          scale: 1.2,
          child: Checkbox(
            onChanged: (value) {
              setState(() {
                isCheckboxActive = value ?? false;
              });
            },
            value: isCheckboxActive,
            activeColor: primary900,
            checkColor: white,
            side: const BorderSide(color: primary900, width: 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: '${'agree_with'.tr()} ',
              style: const TextStyle(
                fontSize: 14,
                color: greyscale700,
                fontWeight: FontWeight.w600,
                fontFamily: Involve,
                height: 1.6,
              ),
              children: [
                TextSpan(
                  recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(termsOfUse)),
                  text: 'term_of_use'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: primary900,
                    fontWeight: FontWeight.w600,
                    fontFamily: Involve,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget planCard(SubscriptionModel plan, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: getTextByLocale(
                      context,
                      plan.title,
                      plan.titleEn,
                    ),
                    fw: FontWeight.w700,
                    maxLine: 2,
                  ),
                  AppText(
                    text: getTextByLocale(
                      context,
                      plan.description,
                      plan.descriptionEn,
                    ),
                    size: 14,
                    color: greyscale600,
                    fw: FontWeight.w600,
                    maxLine: 2,
                  ),
                ],
              ),
            ),
            AppText(
              text: roubleFormat(plan.price),
              fw: FontWeight.w700,
            ),
            const SizedBox(width: 14),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary900, width: 3),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.lens,
                        color: primary900,
                        size: 16,
                      ),
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
