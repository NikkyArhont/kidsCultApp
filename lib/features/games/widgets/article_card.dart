import 'package:cached_network_image/cached_network_image.dart';
import 'package:child_tracker/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ArticleCard extends StatelessWidget {
  final ArticleModel article;
  const ArticleCard({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: greyscale200, width: 3),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                const Expanded(child: SizedBox()),
                if (article.photo != null)
                  Expanded(
                    flex: 1,
                    child: CachedNetworkImage(
                      imageUrl: article.photo!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(child: CupertinoActivityIndicator()),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: AppText(
                text: getTextByLocale(context, article.name, article.nameEng),
                maxLine: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
