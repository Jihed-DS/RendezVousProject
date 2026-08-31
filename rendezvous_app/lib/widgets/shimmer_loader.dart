import 'package:flutter/material.dart';

class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF2A2A34) : const Color(0xFFE8E8ED);
    final highlight = isDark ? const Color(0xFF3A3A46) : const Color(0xFFF5F5F8);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: ShaderMask(
            shaderCallback: (rect) {
              final t = _controller.value;
              return LinearGradient(
                begin: Alignment(-1 - 2 * t, 0),
                end: Alignment(1 - 2 * t + 1, 0),
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(rect);
            },
            child: Container(
              height: widget.height,
              width: widget.width ?? double.infinity,
              color: base,
            ),
          ),
        );
      },
    );
  }
}

/// Squelette d'une carte de liste type "prestataire" — avatar + 2 lignes de texte.
class ShimmerListTile extends StatelessWidget {
  const ShimmerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 56, width: 56, borderRadius: BorderRadius.all(Radius.circular(28))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 14, width: 140),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 11, width: 80),
                  const SizedBox(height: 10),
                  ShimmerBox(height: 11, width: MediaQuery.of(context).size.width * 0.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}