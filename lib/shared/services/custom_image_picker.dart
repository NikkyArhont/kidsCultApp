import 'dart:typed_data';

import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CustomImagePicker {
  static const allowedMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
  ];

  static const allowedVideoMimeTypes = [
    'video/mp4',
    'video/quicktime',
    'video/x-matroska',
    'video/webm',
    'video/3gpp',
    'video/avi',
  ];

  static const allowedPhotoOrPdfMimeTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
    'application/pdf',
  ];

  static const allowedPhotoOrVideoTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/heic',
    'image/heif',
    'video/mp4',
    'video/quicktime',
    'video/x-matroska',
    'video/webm',
    'video/3gpp',
    'video/avi',
  ];

  static final _picker = ImagePicker();

  static Future<XFile?> pickAvatarFromGallery(BuildContext context, {ImageSource? source}) async {
    source ??= await showImageSourceSelectModalBottomSheet(context);

    if (source == null) return null;

    final XFile? xfile = await _picker.pickImage(source: source);

    if (xfile == null) return null;

    final mimeType = lookupMimeType(xfile.path);

    if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
      SnackBarSerive.showErrorSnackBar('onlyPhoto'.tr());
      return null;
    }

    return xfile;
  }

  // static Future<XFile?> pickVideoFromGallery() async {
  //   final XFile? xfile = await _picker.pickVideo(source: ImageSource.gallery);

  //   if (xfile == null) return null;

  //   final mimeType = lookupMimeType(xfile.path);

  //   if (mimeType == null || !allowedVideoMimeTypes.contains(mimeType)) {
  //     SnackBarSerive.showErrorSnackBar('Можно выбрать только видео');
  //     return null;
  //   }

  //   return xfile;
  // }

  static Future<XFile?> pickPhotoOrVideo(BuildContext context) async {
    final XFile? xfile = await _picker.pickMedia();

    if (xfile == null) return null;

    final mimeType = lookupMimeType(xfile.path);

    if (mimeType == null || !allowedPhotoOrVideoTypes.contains(mimeType)) {
      SnackBarSerive.showErrorSnackBar('onlyPhotoOrVideo'.tr());
      return null;
    }

    return xfile;
  }

  static bool isVideo(String path) {
    final mimeType = lookupMimeType(path);
    return allowedVideoMimeTypes.contains(mimeType);
  }

  static bool isVideoUrl(String url) {
    final String path = url.split('?').first;
    final lowerCaseUrl = path.toLowerCase();
    return lowerCaseUrl.endsWith('.mp4') ||
        lowerCaseUrl.endsWith('.mov') ||
        lowerCaseUrl.endsWith('.avi') ||
        lowerCaseUrl.endsWith('.mkv') ||
        lowerCaseUrl.endsWith('.webm') ||
        lowerCaseUrl.endsWith('.flv') ||
        lowerCaseUrl.endsWith('.wmv');
  }

  static Future<Uint8List?> getFileVideoThumbnail(String path) async {
    final thumb = await VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      maxHeight: 120,
      maxWidth: 120,
      quality: 75,
    ).onError((_, e) {
      print(e);
      return null;
    });
    return thumb;
  }

  static Future<String?> getFileVideoThumbnailFromUrl(String url) async {
    final thumb = await VideoThumbnail.thumbnailFile(
      video: url,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.WEBP,
      maxHeight: 100,
      maxWidth: 100,
      quality: 75,
    ).onError((_, e) {
      print(e);
      return null;
    });
    return thumb;
  }
}
