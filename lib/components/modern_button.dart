import 'package:flutter/material.dart';
import 'package:lidarmesure/theme.dart';

/// A modern, animated, pill-shaped button with multiple variants and sizes.
/// Variants use the app ColorScheme. No splash effects are used.
class ModernButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final ModernButtonVariant variant;
  final ModernButtonSize size;
  final bool expand;
  final bool loading;

  const ModernButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.variant = ModernButtonVariant.primary,
    this.size = ModernButtonSize.medium,
    this.expand = false,
    this.loading = false,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null || widget.loading;

    // Dimensions by size
    final double height;
    final EdgeInsets padding;
    switch (widget.size) {
      case ModernButtonSize.small:
        height = 36;
        padding = const EdgeInsets.symmetric(horizontal: 12);
        break;
      case ModernButtonSize.medium:
        height = 44;
        padding = const EdgeInsets.symmetric(horizontal: 16);
        break;
      case ModernButtonSize.large:
        height = 52;
        padding = const EdgeInsets.symmetric(horizontal: 20);
        break;
    }

    // Colors by variant
    Color fg;
    Decoration decoration;
    switch (widget.variant) {
      case ModernButtonVariant.primary:
        fg = cs.onPrimary;
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.tertiary.withValues(alpha: 0.9)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(999),
        );
        break;
      case ModernButtonVariant.tonal:
        fg = cs.onPrimaryContainer;
        decoration = BoxDecoration(
          color: cs.primaryContainer,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
        );
        break;
      case ModernButtonVariant.outline:
        fg = cs.primary;
        decoration = BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.primary.withValues(alpha: 0.6), width: 1.2),
        );
        break;
      case ModernButtonVariant.ghost:
        fg = cs.onSurface;
        decoration = BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
        );
        break;
      case ModernButtonVariant.danger:
        fg = cs.onError;
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.error, cs.error.withValues(alpha: 0.85)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: BorderRadius.circular(999),
        );
        break;
    }

    // Disabled overlay and hover/press effects
    final double opacity = disabled
        ? 0.5
        : (_pressed
            ? 0.9
            : (_hovered ? 0.96 : 1.0));
    final double scale = _pressed ? 0.98 : (_hovered ? 1.01 : 1.0);

    Widget content = AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 150),
      style: Theme.of(context).textTheme.labelLarge!.withColor(fg).medium,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.loading) ...[
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (widget.leadingIcon != null) ...[
            Icon(widget.leadingIcon, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.trailingIcon != null) ...[
            const SizedBox(width: 8),
            Icon(widget.trailingIcon, size: 18, color: fg),
          ],
        ],
      ),
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height),
      child: Padding(
        padding: padding,
        child: Center(child: content),
      ),
    );

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      transform: Matrix4.identity()..scale(scale),
      decoration: decoration,
      padding: EdgeInsets.zero,
      child: Opacity(opacity: opacity, child: content),
    );

    final semantics = Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: button,
    );

    final clickable = GestureDetector(
      onTapDown: disabled
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: disabled
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: disabled
          ? null
          : (_) => setState(() => _pressed = false),
      onTap: disabled ? null : widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: semantics,
    );

    final region = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FocusableActionDetector(
        mouseCursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: clickable)
            : clickable,
      ),
    );

    return region;
  }
}

enum ModernButtonVariant { primary, tonal, outline, ghost, danger }

enum ModernButtonSize { small, medium, large }
