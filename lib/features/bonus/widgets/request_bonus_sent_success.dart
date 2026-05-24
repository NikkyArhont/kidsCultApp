import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RequestBonusSentSuccessScreen extends StatefulWidget {
  final String bonusName;
  final DocumentReference mentorRef;
  const RequestBonusSentSuccessScreen({super.key, required this.bonusName, required this.mentorRef});

  @override
  State<RequestBonusSentSuccessScreen> createState() => _RequestBonusSentSuccessScreenState();
}

class _RequestBonusSentSuccessScreenState extends State<RequestBonusSentSuccessScreen>
    with AutomaticKeepAliveClientMixin {
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppText(
                        text: 'request_bonus_by_kid_sent'.tr(),
                        size: 28,
                        fw: FontWeight.w700,
                        maxLine: 2,
                        color: primary900,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Builder(
                      builder: (context) {
                        return FutureBuilder<UserModel>(
                          future: context.read<UserCubit>().getUserByRef(widget.mentorRef),
                          builder: (context, snapshot) {
                            final user = snapshot.data;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: RichText(
                                text: TextSpan(
                                  text: 'request_bonus_by_kid_sent_text1'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.normal,
                                    color: greyscale800,
                                    fontFamily: Involve,
                                    height: 1.6,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: ' ${widget.bonusName} ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: greyscale800,
                                        fontFamily: Involve,
                                        height: 1.6,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'from_mentor'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: greyscale800,
                                        fontFamily: Involve,
                                        height: 1.6,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' ${user?.name ?? '...'}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: greyscale800,
                                        fontFamily: Involve,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                                maxLines: 10,
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
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
