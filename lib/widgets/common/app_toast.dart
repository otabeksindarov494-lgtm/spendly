import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../theme/app_theme.dart';
import 'glass.dart';

/// Ekranning YUQORI qismida chiqadigan qisqa xabar (toast).
///
/// Status bar ostidan silliq tushib keladi, shisha panel ko'rinishida,
/// [duration] dan keyin o'zi yo'qoladi; bosilsa darhol yopiladi. Bir vaqtda
/// faqat bittasi turadi — yangisi eskisini almashtiradi.
///
/// `ScaffoldMessenger.showSnackBar` o'rniga ishlatiladi (u pastdan chiqadi).
abstract final class AppToast {
  static OverlayEntry? _current;

  static const Duration duration = Duration(milliseconds: 2600);

  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext context) => _ToastView(
        message: message,
        isError: isError,
        onDone: () {
          if (_current == entry) {
            entry.remove();
            _current = null;
          }
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({
    required this.message,
    required this.isError,
    required this.onDone,
  });

  final String message;
  final bool isError;
  final VoidCallback onDone;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(AppToast.duration, _close);
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    _timer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CustomTheme theme = context.theme;
    final Color accent = widget.isError ? theme.red : theme.green;
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1.2),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onTap: _close,
              child: GlassPanel(
                borderRadius: const BorderRadius.all(
                  Radius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      widget.isError
                          ? IconsaxPlusBold.information
                          : IconsaxPlusBold.tick_circle,
                      size: 22,
                      color: accent,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: context.text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
