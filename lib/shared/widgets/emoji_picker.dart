
import 'package:child_tracker/index.dart';
import 'package:flutter/material.dart';

class EmojiPicker extends StatelessWidget {
  final Function (String emoji) onPick;
  const EmojiPicker({super.key, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        children: emojis.map((emoji) {
          return GestureDetector(
            onTap: () => onPick(emoji),
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}