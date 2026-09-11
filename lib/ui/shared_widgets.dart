import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 28),
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.radius,
    this.shadow = true,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final double? radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final cardRadius = radius ?? palette.radius;
    return Container(
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: borderColor ?? palette.line),
        boxShadow: shadow && !palette.isDark
            ? [
                BoxShadow(
                  color: palette.ink.withAlpha(12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      padding: padding,
      child: child,
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 18, color: palette.ink),
        ),
        const Spacer(),
        ...(action == null ? const <Widget>[] : <Widget>[action as Widget]),
      ],
    );
  }
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.label, {this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: color ?? palette.muted,
        fontSize: 10,
        letterSpacing: 1.1,
      ),
    );
  }
}

class SoftPill extends StatelessWidget {
  const SoftPill({
    required this.label,
    this.icon,
    this.color,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final foreground = color ?? palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.accentSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: foreground, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class ThinProgressBar extends StatelessWidget {
  const ThinProgressBar({
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.valueColor,
    super.key,
  });

  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: backgroundColor ?? palette.accentSoft,
        valueColor: AlwaysStoppedAnimation(valueColor ?? palette.accent),
      ),
    );
  }
}

class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final button = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.isDark
            ? const Color(0xFF162116)
            : Colors.white,
        minimumSize: const Size(0, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(palette.radius * .62),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class IconAction extends StatelessWidget {
  const IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: palette.ink),
        style: IconButton.styleFrom(
          backgroundColor: palette.surface,
          side: BorderSide(color: palette.line),
          fixedSize: const Size(42, 42),
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.value,
    required this.label,
    this.icon,
    this.color,
    super.key,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFrom(context);
    final tint = color ?? palette.accent;
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(15),
        shadow: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, color: tint, size: 20),
            const SizedBox(height: 13),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 23,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

AppPalette paletteFrom(BuildContext context) {
  return Theme.of(context).extension<PaletteTheme>()?.palette ??
      paletteFor(AppStyle.paper);
}
