import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class SetChatPhoto extends StatelessWidget {
  const SetChatPhoto({super.key});

  void onPick(BuildContext context) async {
    final XFile? xfile = await CustomImagePicker.pickAvatarFromGallery(context);
    if (xfile != null && context.mounted) {
      context.read<NewChatCubit>().onChangePhoto(xfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewChatCubit, NewChatState>(
      builder: (context, state) {
        final valid = state.photo != null || state.emoji != null;
        return Column(
          children: [
             Padding(
              padding: const EdgeInsets.only(left: 34, right: 24),
              child: MaskotMessage(
                message: 'add_picture'.tr(),
                maskot: '2177-min',
                flip: true,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Column(
                children: [
                  CachedClickableImage(
                    width: 100,
                    height: 100,
                    circularRadius: 300,
                    emojiFontSize: 60,
                    onTap: () => onPick(context),
                    imageFile: state.photo != null ? File(state.photo!.path) : null,
                    emoji: state.emoji,
                    noImageWidget: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(300),
                        border: Border.all(color: greyscale200, width: 2),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.add, size: 40, color: primary900),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: EmojiPicker(
                      onPick: (emoji) {
                        context.read<NewChatCubit>().onChangeEmoji(emoji);
                      },
                    ),
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
                      text: 'buttonNext'.tr(),
                      isActive: valid,
                      onTap: () {
                        if (valid) {
                          context.read<NewChatCubit>().nextPage();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
