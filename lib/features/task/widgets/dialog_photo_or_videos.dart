import 'dart:io';


import 'package:child_tracker/index.dart';

import 'package:flutter/material.dart';

class DialogPhotoOrVideos extends StatelessWidget {
  final List<String> files;
  const DialogPhotoOrVideos({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          children: files.map((file) => photoOrVideoCard(file)).toList(),
        ),
      ],
    );
  }

  Widget photoOrVideoCard(String url) {
    if (CustomImagePicker.isVideoUrl(url)) {
      return _VideoCard(url: url);
    } else {
      return _PhotoCard(url: url);
    }
  }
}

class _VideoCard extends StatelessWidget {
  final String url;

  const _VideoCard({required this.url});

  void onTap(BuildContext context) {
    showFullImageOrVideoUrl(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: GestureDetector(
        onTap: () => onTap(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<String?>(
                future: CustomImagePicker.getFileVideoThumbnailFromUrl(url),
                builder: (context, snapshot) {
                  if (snapshot.data == null) {
                    return Container(
                      color: const Color(0xFFE9F0FF),
                      width: 100,
                      height: 100,
                    );
                  }

                  return Image.file(
                    File(snapshot.data!),
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        color: red.withOpacity(0.1),
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.red),
                        ),
                      );
                    },
                  );
                }),
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
  final String url;

  const _PhotoCard({required this.url});

  void onTap(BuildContext context) {
    showFullImageOrVideoUrl(context, url);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: CachedClickableImage(
        imageUrl: url,
        width: 100,
        height: 100,
        circularRadius: 4,
      ),

    );
  }
}
