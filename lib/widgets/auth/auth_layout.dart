import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final String heading;
  final String subheading;
  final Widget form;
  final Widget footer;

  const AuthLayout({
    super.key,
    required this.heading,
    required this.subheading,
    required this.form,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(flex: 5, child: _BrandPanel()),
                Expanded(
                  flex: 6,
                  child: _FormPanel(
                    heading: heading,
                    subheading: subheading,
                    form: form,
                    footer: footer,
                    showBrandOnTop: false,
                  ),
                ),
              ],
            );
          }

          return _FormPanel(
            heading: heading,
            subheading: subheading,
            form: form,
            footer: footer,
            showBrandOnTop: true,
          );
        },
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  final String heading;
  final String subheading;
  final Widget form;
  final Widget footer;
  final bool showBrandOnTop;

  const _FormPanel({
    required this.heading,
    required this.subheading,
    required this.form,
    required this.footer,
    required this.showBrandOnTop,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: showBrandOnTop
          ? BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primaryContainer.withValues(alpha: 0.55),
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0, 0.45, 1],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            )
          : null,
      color: showBrandOnTop ? null : Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBrandOnTop) ...[
                    const Center(child: _BrandMark(size: 62)),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    heading,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subheading,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha:
                                Theme.of(context).brightness == Brightness.dark
                                ? 0.25
                                : 0.04,
                          ),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: form,
                  ),
                  const SizedBox(height: 20),
                  footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: _Circle(size: 260, opacity: 0.10),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: _Circle(size: 320, opacity: 0.08),
            ),
            Padding(
              padding: const EdgeInsets.all(56),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _BrandMark(size: 48, inverted: true),
                      const SizedBox(width: 14),
                      Text(
                        'TexFlow',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Production\nintelligence for\nmodern textile lines.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _Feature(
                    icon: Icons.track_changes_rounded,
                    text: 'Track every stage of production',
                  ),
                  const _Feature(
                    icon: Icons.warning_amber_rounded,
                    text: 'Catch bottlenecks before they spread',
                  ),
                  const _Feature(
                    icon: Icons.cloud_off_rounded,
                    text: 'Works offline and syncs automatically',
                  ),
                  const Spacer(),
                  Text(
                    'TexFlow Monitoring  -  v1.0',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final double opacity;

  const _Circle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  final bool inverted;

  const _BrandMark({required this.size, this.inverted = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: inverted
            ? null
            : LinearGradient(
                colors: [scheme.primary, scheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: inverted ? Colors.white.withValues(alpha: 0.16) : null,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.factory_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}
