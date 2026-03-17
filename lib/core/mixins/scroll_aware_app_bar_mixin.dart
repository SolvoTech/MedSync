import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Mixin that hides/shows AppBar on scroll direction.
/// Per spec §26.3.
mixin ScrollAwareAppBarMixin<T extends StatefulWidget> on State<T> {
  late final ScrollController scrollController;
  bool isAppBarVisible = true;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final direction = scrollController.position.userScrollDirection;
    final shouldShow = direction == ScrollDirection.forward;

    if (shouldShow != isAppBarVisible) {
      setState(() => isAppBarVisible = shouldShow);
    }
  }

  /// Build a SliverAppBar that responds to scroll.
  SliverAppBar buildScrollAwareAppBar({
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) {
    return SliverAppBar(
      floating: true,
      snap: true,
      title: Text(title),
      actions: actions,
      bottom: bottom,
    );
  }
}
