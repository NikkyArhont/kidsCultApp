import 'dart:io';
import 'dart:typed_data';

import 'package:child_tracker/index.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PhotoVideoPicker extends StatefulWidget {
  final List<XFile> files;
  final Function(XFile file) onAdd;
  final Function(XFile file) onRemove;
  const PhotoVideoPicker({super.key, required this.files, required this.onAdd, required this.onRemove});

  @override
  State<PhotoVideoPicker> createState() => _PhotoVideoPickerState();
}

class _PhotoVideoPickerState extends State<PhotoVideoPicker> {
  void onTapAdd() async {
    final XFile? xfile = await CustomImagePicker.pickPhotoOrVideo(context);
    if (xfile != null && context.mounted) {
      widget.onAdd(xfile);
    }
  }

  void onRemove(XFile file) {
    widget.onRemove(file);
  }

  @override
  Widget build(BuildContext context) {
    bool isLimited = widget.files.length >= 6;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      shrinkWrap: true,
      itemCount: isLimited ? widget.files.length : widget.files.length + 1,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 11.0,
        mainAxisSpacing: 11.0,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        if (index == 0 && !isLimited) {
          return addWidget();
        } else {
          return photoOrVideoCard(widget.files[!isLimited ? index - 1 : index]);
        }
      },
    );
  }

  Widget addWidget() {
    return DottedBorder(
      borderPadding: const EdgeInsets.only(top: 0),
      borderType: BorderType.RRect,
      radius: const Radius.circular(10),
      color: primary900,
      dashPattern: const [8, 8],
      child: GestureDetector(
        onTap: onTapAdd,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: const Color(0xFFE9F0FF),
          ),
          child: Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: white,
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.add,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget photoOrVideoCard(XFile file) {
    if (CustomImagePicker.isVideo(file.path)) {
      return _VideoCard(file: file, onRemove: () => onRemove(file));
    } else {
      return _PhotoCard(file: file, onRemove: () => onRemove(file));
    }
  }
}

class _VideoCard extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _VideoCard({required this.file, required this.onRemove});

  void onTap(BuildContext context) {
    showFullImageOrVideoFile(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Stack(
          children: [
            FutureBuilder<Uint8List?>(
                future: CustomImagePicker.getFileVideoThumbnail(file.path),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Container(
                      color: const Color(0xFFE9F0FF),
                    );
                  }

                  return Image.memory(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: red.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                        ),
                      );
                    },
                  );
                }),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: white,
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.clear,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: primary900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;
  const _PhotoCard({required this.file, required this.onRemove});

  void onTap(BuildContext context) {
    showFullImageOrVideoFile(context, file);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: white,
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.clear,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
