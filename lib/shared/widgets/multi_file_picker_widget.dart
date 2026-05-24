import 'dart:io';
import 'dart:typed_data';

import 'package:child_tracker/index.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MultiFilePickerWidget extends StatefulWidget {
  final List<File> files;
  final int maxLenght;
  final void Function(File file) onFilePicked;
  final void Function(File file) onFileRemoved;
  final String label;
  const MultiFilePickerWidget({
    super.key,
    required this.files,
    this.maxLenght = 6,
    required this.onFilePicked,
    required this.onFileRemoved,
    required this.label,
  });

  @override
  State<MultiFilePickerWidget> createState() => _MultiFilePickerWidgetState();
}

class _MultiFilePickerWidgetState extends State<MultiFilePickerWidget> {
  void onAddFile() async {
    if (widget.files.length >= widget.maxLenght) {
      SnackBarSerive.showErrorSnackBar('limit'.tr());
      return;
    }
    final pickedFile = await CustomImagePicker.pickPhotoOrVideo(context);
    if (pickedFile != null) {
      widget.onFilePicked(File(pickedFile.path));
    }
  }

  void onDeleteFile(int index) {
    widget.onFileRemoved(widget.files[index]);
  }

  @override
  Widget build(BuildContext context) {
    final int itemCount = widget.files.length + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(text: widget.label),
        const SizedBox(height: 12),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AddMediaButton(onTap: onAddFile);
            } else {
              final mediaFile = widget.files[index - 1];
              return _SelectedMediaItem(
                mediaFile: mediaFile,
                onDelete: () => onDeleteFile(index - 1),
              );
            }
          },
        ),
      ],
    );
  }
}

class _AddMediaButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMediaButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: DottedBorder(
        borderPadding: const EdgeInsets.only(top: 0),
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: primary900,
        dashPattern: const [8, 8],
        child: Container(
          alignment: Alignment.bottomRight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: primary50,
          ),
          child: Container(
            height: 28,
            width: 28,
            margin: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: white,
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.add,
                size: 20,
                color: greyscale900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedMediaItem extends StatelessWidget {
  final File mediaFile;
  final VoidCallback onDelete;

  const _SelectedMediaItem({
    required this.mediaFile,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    bool isVideo = CustomImagePicker.isVideo(mediaFile.path);
    Widget imageWidget;
    if (!isVideo) {
      imageWidget = Image.file(
        File(mediaFile.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      imageWidget = FutureBuilder<Uint8List?>(
        future: CustomImagePicker.getFileVideoThumbnail(mediaFile.path),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          } else {
            return Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(
                  Icons.videocam,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            );
          }
        },
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: imageWidget,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              height: 28,
              width: 28,
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.clear,
                  size: 20,
                  color: greyscale900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
