import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/app_haptics.dart';

/// Reusable institutional-grade market search bar with dynamic focus glow,
/// animated clear rotation, and theme-adaptive styling.
class MarketSearchBar extends StatefulWidget {
  const MarketSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = 'Search ticker symbol, company, or sector...',
    this.onChanged,
    this.onClear,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 10),
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry padding;
  final bool autofocus;

  @override
  State<MarketSearchBar> createState() => _MarketSearchBarState();
}

class _MarketSearchBarState extends State<MarketSearchBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clearIconAnimController;
  late final Animation<double> _clearIconRotation;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _clearIconAnimController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _clearIconRotation = CurvedAnimation(
      parent: _clearIconAnimController,
      curve: Curves.easeInOutCubic,
    );

    widget.controller.addListener(_handleTextChange);
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant MarketSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChange);
      widget.controller.addListener(_handleTextChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        _internalFocusNode?.removeListener(_handleFocusChange);
        _internalFocusNode?.dispose();
        _internalFocusNode = null;
      } else {
        oldWidget.focusNode?.removeListener(_handleFocusChange);
      }

      if (widget.focusNode == null) {
        _internalFocusNode = FocusNode();
        _internalFocusNode!.addListener(_handleFocusChange);
      } else {
        widget.focusNode!.addListener(_handleFocusChange);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    _clearIconAnimController.dispose();
    super.dispose();
  }

  void _handleClear() {
    AppHaptics.light();
    _clearIconAnimController.forward(from: 0.0);
    widget.controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final isFocused = _effectiveFocusNode.hasFocus;
    final activeBorderColor = isFocused ? AppColors.primaryBlue : borderColor;
    final activeBorderWidth = isFocused ? 1.6 : 1.2;

    return Padding(
      padding: widget.padding,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: activeBorderColor,
            width: activeBorderWidth,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: isDark ? 0.28 : 0.14,
                    ),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : (isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]),
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          textCapitalization: TextCapitalization.none,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: textSecondary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 22,
              color: (isFocused || widget.controller.text.isNotEmpty)
                  ? AppColors.primaryBlue
                  : textSecondary,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? RotationTransition(
                    turns: _clearIconRotation,
                    child: IconButton(
                      splashRadius: 20,
                      tooltip: 'Clear search',
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? AppColors.darkSurfaceSecondary
                              : AppColors.lightSurfaceSecondary,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 15,
                          color: textSecondary,
                        ),
                      ),
                      onPressed: _handleClear,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }
}
