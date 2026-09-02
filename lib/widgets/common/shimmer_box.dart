import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Yuklanish paytidagi skeleton bloki (PROJECT.md 7-bosqich).
///
/// `shimmerBase` / `shimmerHighlight` ranglaridan foydalanadi, qo'shimcha
/// paket talab qilmaydi.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: <Color>[
                theme.shimmerBase,
                theme.shimmerHighlight,
                theme.shimmerBase,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ro'yxat o'rniga ko'rsatiladigan bir nechta skeleton qator.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.itemCount = 4, this.itemHeight = 72});

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        itemCount,
        (int index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ShimmerBox(height: itemHeight, borderRadius: 16),
        ),
      ),
    );
  }
}
