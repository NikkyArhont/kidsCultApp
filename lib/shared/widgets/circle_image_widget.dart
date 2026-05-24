import 'dart:io';
import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CachedClickableImage extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String? emoji;
  final double emojiFontSize;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final double? circularRadius;
  final VoidCallback? onTap;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Widget? noImageWidget;
  final Widget? emojiWidget;

  const CachedClickableImage({
    super.key,
    this.imageUrl,
    this.imageFile,
    this.width,
    this.height,
    this.borderRadius,
    this.circularRadius,
    this.onTap,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.noImageWidget,
    this.emoji,
    this.emojiFontSize = 50,
    this.emojiWidget,
  }) : assert(!(borderRadius != null && circularRadius != null), 'Either borderRadius or circularRadius can be set, but not both.');

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (imageFile != null) {
      imageWidget = Image.file(
        imageFile!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    } else if (imageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          color: const Color.fromARGB(255, 249, 248, 248),
          child: Center(child: placeholder ?? const CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade300,
          child: errorWidget ?? const Icon(Icons.error),
        ),
      );
    } else if (emoji != null) {
      imageWidget = emojiWidget ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(300),
              border: Border.all(color: greyscale200, width: 2),
              color: greyscale100,
            ),
            child: Center(
              child: Text(
                emoji!,
                style: TextStyle(fontSize: emojiFontSize),
              ),
            ),
          );
    } else {
      imageWidget = SizedBox(
        width: width,
        height: height,
        child: noImageWidgetPlaceholder(),
      );
    }

    if (circularRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(circularRadius!),
        child: imageWidget,
      );
    } else if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return InkWell(
      radius: circularRadius,
      borderRadius: circularRadius != null ? BorderRadius.circular(circularRadius!) : null,
      onTap: onTap,
      child: imageWidget,
    );
  }

  Widget noImageWidgetPlaceholder() {
    return noImageWidget ??
        Container(
          width: width,
          height: height,
          color: greyscale100,
          child: Center(
            child: Image.asset(
              'assets/images/no_image.png',
            ),
          ),
        );
  }
}
