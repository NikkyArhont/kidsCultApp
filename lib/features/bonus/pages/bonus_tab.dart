import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class BonusTabScreen extends StatefulWidget {
  const BonusTabScreen({super.key});

  @override
  State<BonusTabScreen> createState() => _BonusTabScreenState();
}

class _BonusTabScreenState extends State<BonusTabScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BonusCubit>().init();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserModel?>(
      builder: (context, me) {
        if (me == null) {
          return Container(
            constraints: const BoxConstraints(),
            color: white,
          );
        }
        return BlocConsumer<BonusCubit, BonusState>(
          listener: (context, state) {
            if (state.status == BonusStateStatus.error) {
              SnackBarSerive.showErrorSnackBar(state.errorMessage ?? defaultErrorText);
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: greyscale100,
              appBar: AppBar(
                backgroundColor: white,
                automaticallyImplyLeading: false,
                toolbarHeight: 72,
                leadingWidth: 0,
                title: me.isKid ? KidBonusAppBarWidget(me: me, selectedMentor: state.selectedMentor) : MentorBonusAppbarWidget(selectedKid: state.selectedKid),
              ),
              floatingActionButton: SizedBox(
                width: 56,
                height: 56,
                child: FloatingActionButton(
                  onPressed: () async {
                    // if (me.isKid) {
                    //   context.push('/create_bonus');
                    // } else {
                    //   context.push('/create_bonus');
                    // }

                    if (me.hasSubscription()) {
                      context.push('/create_bonus');
                    } else {
                      bool? confirm = await showPlanExpiredModalBottomSheet(context, 'get_subs_for_action'.tr());
                      if (confirm == true && context.mounted) {
                        context.push('/current_subscription');
                      }
                    }
                  },
                  elevation: 4,
                  backgroundColor: primary900,
                  shape: const CircleBorder(),
                  child: const Icon(CupertinoIcons.add, color: white, size: 28),
                ),
              ),
              body: state.status == BonusStateStatus.loading
                  ? const Center(child: CircularProgressIndicator())
                  : BonusListWidget(
                      bonuses: state.bonuses,
                      selectedChip: state.selectedChip,
                      me: me,
                    ),
            );
          },
        );
      },
    );
  }
}
