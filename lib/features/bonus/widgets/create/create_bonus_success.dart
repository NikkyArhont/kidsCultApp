import 'package:child_tracker/index.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CreateBonusSuccessScreen extends StatefulWidget {
  const CreateBonusSuccessScreen({super.key});

  @override
  State<CreateBonusSuccessScreen> createState() => _CreateBonusSuccessScreenState();
}

class _CreateBonusSuccessScreenState extends State<CreateBonusSuccessScreen> with AutomaticKeepAliveClientMixin {
  late ConfettiController _controllerTopCenter;

  @override
  void initState() {
    super.initState();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
  }

  @override
  void dispose() {
    _controllerTopCenter.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: white,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _controllerTopCenter,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              shouldLoop: true,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BottomArrowBubleShape(
                      child: AppText(
                        text: 'accountReadyTitle'.tr(),
                        size: 24,
                        fw: FontWeight.w700,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      'assets/images/2184-min.png',
                      fit: BoxFit.contain,
                      width: 240,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      text: 'bonus_created'.tr(),
                      size: 32,
                      fw: FontWeight.w700,
                      color: primary900,
                    ),
                    const SizedBox(height: 10),
                    BlocBuilder<UserCubit, UserModel?>(
                      builder: (context, me) {
                        bool isKid = me?.isKid ?? false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AppText(
                            text: isKid ? 'bonus_created_text2'.tr() : 'bonus_created_text'.tr(),
                            size: 16,
                            fw: FontWeight.w400,
                            color: greyscale800,
                            maxLine: 3,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: greyscale100))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FilledAppButton(
                        text: 'ok'.tr(),
                        onTap: () {
                          context.pop();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
