import 'dart:io';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditChatPhotoScreen extends StatefulWidget {
  final ChatModel chat;
  const EditChatPhotoScreen({super.key, required this.chat});

  @override
  State<EditChatPhotoScreen> createState() => _EditChatPhotoScreenState();
}

class _EditChatPhotoScreenState extends State<EditChatPhotoScreen> {
  XFile? selectedFile;
  String? selectedEmoji;
  bool isLoading = false;

  void onPick(BuildContext context) async {
    final XFile? xfile = await CustomImagePicker.pickAvatarFromGallery(context);
    if (xfile != null && context.mounted) {
      setState(() {
        selectedFile = xfile;
        selectedEmoji = null;
      });
    }
  }

  void onSave() async {
    bool valid = selectedFile != null || selectedEmoji != null;
    if (valid) {
      setState(() {
        isLoading = true;
      });

      String? photo;

      if (selectedFile != null) {
        final uploadService = FirebaseStorageService();
        final photoUrl = await uploadService.uploadFile(
          file: selectedFile!,
          type: UploadType.chat,
          uid: widget.chat.id,
        );
        if (photoUrl == null) {
          SnackBarSerive.showErrorSnackBar('photoUploadError'.tr());
          return;
        } else {
          photo = photoUrl;
        }
      } else if (selectedEmoji != null) {
        photo = 'emoji:$selectedEmoji';
      }

      await widget.chat.ref.update({'photo': photo});

      setState(() {
        widget.chat.photo = photo;
        isLoading = false;
      });
      if (mounted) {
        SnackBarSerive.showSuccessSnackBar('photo_updated'.tr());
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool valid = selectedFile != null || selectedEmoji != null;
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: AppText(
          text: 'chatPhoto'.tr(),
          size: 24,
          fw: FontWeight.w700,
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 34, right: 24),
            child: MaskotMessage(
              message: 'add_a_picture_prompt'.tr(),
              maskot: '2177-min',
              flip: true,
            ),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Column(
              children: [
                Builder(builder: (context) {
                  bool isEmoji = widget.chat.photo!.startsWith('emoji:');
                  return CachedClickableImage(
                    width: 100,
                    height: 100,
                    circularRadius: 300,
                    emojiFontSize: 60,
                    onTap: () => onPick(context),
                    imageUrl: isEmoji ? null : widget.chat.photo,
                    imageFile: selectedFile != null ? File(selectedFile!.path) : null,
                    emoji: selectedEmoji ?? (isEmoji ? widget.chat.photo!.replaceAll('emoji:', '') : null),
                    noImageWidget: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(300),
                        border: Border.all(color: greyscale200, width: 2),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.add, size: 40, color: primary900),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 40),
                Expanded(
                  child: EmojiPicker(
                    onPick: (emoji) {
                      setState(() {
                        selectedEmoji = emoji;
                        selectedFile = null;
                      });
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
                    text: 'save'.tr(),
                    isActive: valid,
                    onTap: valid ? onSave : null,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
