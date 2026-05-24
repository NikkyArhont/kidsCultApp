import 'package:child_tracker/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class KidDetailScreen extends StatefulWidget {
  final DocumentReference kidRef;
  const KidDetailScreen({super.key, required this.kidRef});

  @override
  State<KidDetailScreen> createState() => _KidDetailScreenState();
}

class _KidDetailScreenState extends State<KidDetailScreen> {
  late UserModel kid;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    final kidSnap = await widget.kidRef.get();
    kid = UserModel.fromFirestore(kidSnap);
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        color: white,
        constraints: const BoxConstraints.expand(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(text: 'roleSelectionKid'.tr(), size: 24, fw: FontWeight.w700),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CachedClickableImage(
                  circularRadius: 100,
                  width: 80,
                  height: 80,
                  imageUrl: kid.photo,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: kid.name,
                        size: 20,
                        fw: FontWeight.w700,
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        text: '${kid.getAge} ${"ageInputYearsOld".tr()}, ${kid.city}',
                        size: 16,
                        fw: FontWeight.w500,
                        color: greyscale700,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            BlocBuilder<UserCubit, UserModel?>(
              builder: (context, me) {
                if (me == null) return const SizedBox();
                if (kid.dairyMembers.contains(me.ref)) {
                  return Column(
                    children: [
                      ProfileMenuCard(
                        onTap: () => context.push('/dairy', extra: kid),
                        icon: 'diary',
                        title: 'myDiary'.tr(),
                        color: const Color(0xFF246BFD).withOpacity(0.08),
                      ),
                      const Divider(height: 48, thickness: 1, color: greyscale200),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
            ProfileMenuCard(
              onTap: () => context.push('/kid_progress', extra: kid),
              icon: 'progress',
              title: 'taskProgress'.tr(),
              color: const Color(0xFF246BFD).withOpacity(0.08),
            ),
            const SizedBox(height: 24),
            ProfileMenuCard(
              onTap: () => context.push('/kid_coins', extra: kid),
              icon: 'coin',
              title: 'taskPoints'.tr(),
              color: orange.withOpacity(0.08),
            ),
            const Divider(height: 48, thickness: 1, color: greyscale200),
            ProfileMenuCard(
              onTap: () {
                final Map<String, dynamic> extra = {
                  'user': kid,
                  'canAdd': false,
                  'showChat': false,
                  'showDelete': false,
                };
                context.push('/connections', extra: extra);
              },
              icon: '3user',
              title: 'myMentors'.tr(),
              iconColor: blue,
              color: const Color(0xFF235DFF).withOpacity(0.08),
            ),
          ],
        ),
      ),
    );
  }
}
