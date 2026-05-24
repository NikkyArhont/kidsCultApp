
import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<UserModel?> showBonusKidSelectorModalBottomSheet(BuildContext context) async {
  return showModalBottomSheet<UserModel?>(
    context: context,
    backgroundColor: white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) => const _SelectBonusMentorContent(),
  );
}

class _SelectBonusMentorContent extends StatefulWidget {
  const _SelectBonusMentorContent();

  @override
  State<_SelectBonusMentorContent> createState() => _SelectBonusMentorContentState();
}

class _SelectBonusMentorContentState extends State<_SelectBonusMentorContent> {
  UserModel? selectedKid;

  @override
  initState() {
    super.initState();
    selectedKid = context.read<BonusCubit>().state.selectedKid;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: BlocBuilder<UserCubit, UserModel?>(
        builder: (context, me) {
          if (me == null) return const SizedBox();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: greyscale200,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              AppText(text: 'selectKid'.tr(), size: 24, fw: FontWeight.w700),
              const Divider(height: 40, thickness: 1, color: greyscale200),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 2,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/images/2177-min.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: LeftArrowBubleShape(
                      child: AppText(
                        text: 'whoToSeeBonus'.tr(),
                        size: 20,
                        maxLine: 10,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      UserSelector(
                        onTap: () {
                          setState(() {
                            selectedKid = null;
                          });
                        },
                        isSelected: selectedKid == null,
                        name: 'all_kids'.tr(),
                        placeholder: Image.asset('assets/images/all_kids.png'),
                      ),
                      ...me.connections.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: FutureBuilder<UserModel>(
                              future: context.read<UserCubit>().getUserByRef(e),
                              builder: (context, snapshot) {
                                final user = snapshot.data;
                                if (user == null) {
                                  return const SizedBox(
                                    width: double.infinity,
                                    height: 90,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                return UserSelector(
                                  onTap: () {
                                    setState(() {
                                      selectedKid = user;
                                    });
                                  },
                                  image: user.photo,
                                  isSelected: selectedKid?.id == e.id,
                                  name: user.name,
                                );
                              }),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: greyscale200),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledSecondaryAppButton(
                      text: 'cancel'.tr(),
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledAppButton(
                      text: 'select'.tr(),
                      onTap: () {
                        context.read<BonusCubit>().onKidSelected(selectedKid);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }
}
