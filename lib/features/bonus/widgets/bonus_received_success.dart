import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class BonusReceivedSuccessScreen extends StatefulWidget {
  final String bonusName;
  final DocumentReference kidRef;
  final DocumentReference mentorRef;
  const BonusReceivedSuccessScreen({super.key, required this.bonusName, required this.mentorRef, required this.kidRef});

  @override
  State<BonusReceivedSuccessScreen> createState() => _BonusReceivedSuccessScreenState();
}

class _BonusReceivedSuccessScreenState extends State<BonusReceivedSuccessScreen> with AutomaticKeepAliveClientMixin {
  late ConfettiController _controllerTopCenter;
  late final SoundPlayerService _soundPlayer;

  UserModel? mentor;
  UserModel? kid;

  void initUsers() async {
    final List<DocumentSnapshot> snapshots = await Future.wait([
      widget.mentorRef.get(),
      widget.kidRef.get(),
    ]);

    final mentorSnapshot = snapshots[0];
    final kidSnapshot = snapshots[1];

    if (mentorSnapshot.exists) {
      mentor = UserModel.fromFirestore(mentorSnapshot);
    }
    if (kidSnapshot.exists) {
      kid = UserModel.fromFirestore(kidSnapshot);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    initUsers();
    _controllerTopCenter = ConfettiController(duration: const Duration(seconds: 5));
    _controllerTopCenter.play();
    _soundPlayer = sl<SoundPlayerService>();
    _soundPlayer.playWinGame();
  }

  @override
  void dispose() {
    _soundPlayer.dispose();
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
                        text: 'bonus_received'.tr(),
                        size: 28,
                        fw: FontWeight.w700,
                        maxLine: 2,
                        color: primary900,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: RichText(
                        text: TextSpan(
                          text: '${kid?.name ?? '...'} ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: greyscale800,
                            fontFamily: Involve,
                            height: 1.6,
                          ),
                          children: [
                            TextSpan(
                              text: 'receiving_bonus'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: greyscale800,
                                fontFamily: Involve,
                                height: 1.6,
                              ),
                            ),
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
                              text: ' ${mentor?.name ?? '...'}',
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
                    )
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
