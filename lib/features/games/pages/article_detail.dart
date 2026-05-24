import 'package:child_tracker/index.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArticleDetailScreen extends StatelessWidget {
  final ArticleModel article;
  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        leadingWidth: 70,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    text: getTextByLocale(context, article.name, article.nameEng),
                    size: 32,
                    fw: FontWeight.w700,
                    maxLine: 10,
                    height: 1.4,
                  ),
                ),
                CachedClickableImage(
                  width: 120,
                  height: 120,
                  circularRadius: 12,
                  imageUrl: article.photo,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AppText(
              text: '${"publicated".tr()} ${dateToStringDDMMYYYY(article.createdAt)}',
              size: 12,
              fw: FontWeight.w400,
              color: greyscale700,
            ),
            const Divider(color: greyscale200, thickness: 1, height: 48),
            AppText(
              text: getTextByLocale(context, article.description ?? '', article.descriptionEng ?? ''),
              fw: FontWeight.w400,
              color: greyscale800,
              maxLine: 100,
              height: 1.4,
            ),
          ],
        ),
      ),
    );
  }
}
