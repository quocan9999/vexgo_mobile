import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_typography.dart';
import '../design/discovery_theme.dart';

class FlatFilterOption {
  final String label;
  final int? count;
  final Key? key;
  const FlatFilterOption(this.label, {this.count, this.key});
}

/// Flat category/status tabs; the selected state is also exposed by native TabBar semantics.
class FlatFilterBar extends StatefulWidget {
  final List<FlatFilterOption> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const FlatFilterBar({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  State<FlatFilterBar> createState() => _FlatFilterBarState();
}

class _FlatFilterBarState extends State<FlatFilterBar>
    with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.options.length,
      initialIndex: widget.selectedIndex,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(FlatFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      _controller.dispose();
      _controller = TabController(
        length: widget.options.length,
        initialIndex: widget.selectedIndex,
        vsync: this,
      );
    } else if (_controller.index != widget.selectedIndex) {
      _controller.index = widget.selectedIndex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    final height = math.max(48.0, scale.scale(14) * 1.4 + 20);
    return Material(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scroll =
              constraints.maxWidth < widget.options.length * 112 ||
              scale.scale(1) > 1.3;
          return TabBar(
            controller: _controller,
            isScrollable: scroll,
            tabAlignment: scroll ? TabAlignment.start : TabAlignment.fill,
            onTap: widget.onChanged,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: DiscoveryColors.primary,
            unselectedLabelColor: DiscoveryColors.neutral600,
            labelStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            indicatorColor: DiscoveryColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: DiscoveryColors.neutral200,
            tabs: [
              for (final option in widget.options)
                Tab(
                  key: option.key,
                  height: height,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(option.label),
                      if (option.count != null && option.count! > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${option.count}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
