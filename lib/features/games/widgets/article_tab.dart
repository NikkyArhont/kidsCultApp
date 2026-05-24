
import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ArticleTabWidget extends StatelessWidget {
  const ArticleTabWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArticleModel>>(
        stream: getArticles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppText(
                    text: snapshot.error.toString(),
                    size: 12,
                    fw: FontWeight.normal,
                    color: greyscale500,
                    maxLine: 5,
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }
          final articles = snapshot.data ?? [];
          return GridView.builder(
            itemCount: articles.length,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (context, index) => GestureDetector(
              onTap: () => context.push('/level_detail', extra: articles[index]),
              child: ArticleCard(article: articles[index])),
          );
        });
  }
}

Stream<List<ArticleModel>> getArticles() {
  return ArticleModel.collection
      .where('status', isEqualTo: ArticleStatus.active.name)
      .orderBy('index', descending: false)
      .snapshots()
      .map((event) => event.docs.map((e) => ArticleModel.fromFirestore(e)).toList());
}
