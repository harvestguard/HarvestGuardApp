



import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget {
  const ChatAppBar({
    super.key,
    required this.title,
    required this.leftIcon,
    required this.rightIcon,
  });
  final String title;
  final Widget leftIcon;
  final Widget rightIcon;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            leftIcon,
            const Spacer(),
            const SizedBox(
              width: 150,
              child: FlexibleSpaceBar(
                background: null,
                expandedTitleScale: 1.75,
                titlePadding: EdgeInsets.only(bottom: 10),
                title: null,
              ),
            ),
            const Spacer(),
            rightIcon,
          ],
        ),
      ),
    );
  }
}
