import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/shortlist_model.dart';

/// Кнопка «Избранное» в AppBar-е с живым счётчиком.
/// Consumer перестраивает только badge, а не весь экран.
class ShortlistButton extends StatelessWidget {
  /// Вкладка, внутри которой открыть избранное: '/discover' или '/matches'.
  final String basePath;

  const ShortlistButton({super.key, required this.basePath});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Избранное',
      onPressed: () => context.push('$basePath/favorites'),
      icon: Consumer<ShortlistModel>(
        builder: (context, shortlist, child) => Badge(
          isLabelVisible: shortlist.count > 0,
          label: Text('${shortlist.count}'),
          child: child!,
        ),
        child: const Icon(Icons.star_outline),
      ),
    );
  }
}
