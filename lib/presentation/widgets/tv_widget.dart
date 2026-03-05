import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme.dart';
import '../providers/tv_state_provider.dart';
import 'tv/tv_eyes.dart';
import 'tv/tv_equalizer.dart';
import 'tv/tv_pending.dart';
import 'tv/tv_thinking.dart';
import 'tv/tv_led.dart';

class TvWidget extends ConsumerWidget {
  const TvWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvState = ref.watch(tvStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.92;
        return Center(
          child: Container(
            width: width,
            height: AppSpacing.tvHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF0D0D0D),
              border: Border.all(
                color: const Color(0x40FFC864), // rgba(255, 200, 100, 0.25)
                width: AppSpacing.tvBorderWidth,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.tvBorderRadius),
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              children: [
                // Content layer
                Center(
                  child: _buildContent(tvState),
                ),
                // Scanline overlay
                const _ScanlineOverlay(),
                // LED indicator
                Positioned(
                  bottom: 10,
                  right: 12,
                  child: TvLed(
                    isActive: tvState != TvState.pending &&
                        tvState != TvState.thinking,
                    isPending: tvState == TvState.pending,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(TvState state) {
    switch (state) {
      case TvState.idle:
      case TvState.listening:
        return const TvEyes();
      case TvState.speaking:
        return const TvEqualizer();
      case TvState.pending:
        return const TvPending();
      case TvState.thinking:
        return const TvThinking();
    }
  }
}

class _ScanlineOverlay extends StatelessWidget {
  const _ScanlineOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _ScanlinePainter(),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x08000000) // very subtle dark lines
      ..strokeWidth = 1.0;

    // Draw horizontal scanlines every 3px
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) => false;
}
