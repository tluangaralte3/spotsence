import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/dare_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dare_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ScratchCardScreen — animated scratch-off reward card
// ─────────────────────────────────────────────────────────────────────────────

class ScratchCardScreen extends ConsumerStatefulWidget {
  final ScratchCard card;

  const ScratchCardScreen({super.key, required this.card});

  @override
  ConsumerState<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends ConsumerState<ScratchCardScreen>
    with TickerProviderStateMixin {
  late final ScratchController _scratchController;
  late final AnimationController _revealController;
  late final AnimationController _shimmerController;
  late final Animation<double> _revealAnim;

  bool _isScratched = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _isScratched = widget.card.isScratched;
    _scratchController = ScratchController();

    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _revealAnim = CurvedAnimation(
      parent: _revealController,
      curve: Curves.easeOutBack,
    );

    if (_isScratched) {
      _revealController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _scratchController.dispose();
    _revealController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _onScratchComplete() async {
    if (_isScratched || _processing) return;
    setState(() => _processing = true);

    await ref
        .read(dareControllerProvider.notifier)
        .scratchCard(userId: widget.card.userId, cardId: widget.card.id);

    setState(() {
      _isScratched = true;
      _processing = false;
    });
    _revealController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scratch Card',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Header text
            const Text(
              'Dare Reward',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.card.dareTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // The scratch card
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Reward layer (revealed underneath)
                  AnimatedBuilder(
                    animation: _revealAnim,
                    builder: (context, child) => Transform.scale(
                      scale: 0.9 + 0.1 * _revealAnim.value,
                      child: Opacity(
                        opacity: _revealAnim.value,
                        child: child,
                      ),
                    ),
                    child: _RewardCard(
                      card: widget.card,
                      shimmer: _shimmerController,
                    ),
                  ),

                  // Scratch layer on top
                  if (!_isScratched)
                    ScratchLayer(
                      controller: _scratchController,
                      width: 300,
                      height: 360,
                      onScratchThreshold: _onScratchComplete,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            if (!_isScratched) ...[
              const Text(
                'Scratch to reveal your reward!',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Scratch hint animation
              _ScratchHintWidget(shimmer: _shimmerController),
            ] else
              _RewardDescription(card: widget.card),

            const Spacer(),

            if (_isScratched)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: FilledButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Iconsax.tick_circle),
                  label: const Text('Awesome!'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.bg,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ScratchLayer — custom painter that tracks touch to reveal underneath
// ─────────────────────────────────────────────────────────────────────────────

class ScratchController extends ChangeNotifier {
  final List<Offset?> _points = [];
  double _scratchedPercent = 0;

  List<Offset?> get points => _points;
  double get scratchedPercent => _scratchedPercent;

  void addPoint(Offset? point) {
    _points.add(point);
    notifyListeners();
  }

  void updatePercent(double p) {
    _scratchedPercent = p;
    notifyListeners();
  }
}

class ScratchLayer extends StatefulWidget {
  final ScratchController controller;
  final double width;
  final double height;
  final VoidCallback onScratchThreshold;

  const ScratchLayer({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    required this.onScratchThreshold,
  });

  @override
  State<ScratchLayer> createState() => _ScratchLayerState();
}

class _ScratchLayerState extends State<ScratchLayer> {
  bool _thresholdReached = false;

  void _onPanUpdate(DragUpdateDetails details, RenderBox? box) {
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    widget.controller.addPoint(local);

    // Estimate scratched area
    final total = widget.width * widget.height;
    final scratched = widget.controller.points.where((p) => p != null).length
        * 30.0 * 30.0; // approx brush size
    final pct = (scratched / total).clamp(0.0, 1.0);
    widget.controller.updatePercent(pct);

    if (pct > 0.45 && !_thresholdReached) {
      _thresholdReached = true;
      widget.onScratchThreshold();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        final box = context.findRenderObject() as RenderBox?;
        _onPanUpdate(d, box);
      },
      onPanEnd: (_) => widget.controller.addPoint(null),
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ScratchPainter(
            points: widget.controller.points,
            width: widget.width,
            height: widget.height,
          ),
        ),
      ),
    );
  }
}

class _ScratchPainter extends CustomPainter {
  final List<Offset?> points;
  final double width;
  final double height;

  _ScratchPainter({
    required this.points,
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the foil layer
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final bgRRect = RRect.fromRectAndRadius(bgRect, const Radius.circular(20));

    // Gold foil gradient
    final bgGrad = ui.Gradient.linear(
      const Offset(0, 0),
      Offset(size.width, size.height),
      const [
        Color(0xFFFFD700),
        Color(0xFFFFA500),
        Color(0xFFFFD700),
        Color(0xFFDAA520),
      ],
      [0, 0.3, 0.7, 1],
    );
    final bgPaint = Paint()..shader = bgGrad;
    canvas.save();
    canvas.clipRRect(bgRRect);
    canvas.drawRect(bgRect, bgPaint);

    // Pattern on foil
    final patternPaint = Paint()
      ..color = const Color(0x20FFD700)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), patternPaint);
    }

    // Scratch text on foil
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '✦ SCRATCH HERE ✦',
        style: TextStyle(
          color: Color(0x80000000),
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );

    // Scratch out using DST_OUT blend mode
    final eraserPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 45
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      if (current != null && next != null) {
        canvas.drawLine(current, next, eraserPaint);
      } else if (current != null && next == null) {
        canvas.drawCircle(current, 22, eraserPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScratchPainter old) => old.points.length != points.length;
}

// ─────────────────────────────────────────────────────────────────────────────
// Reward card — shown revealed
// ─────────────────────────────────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final ScratchCard card;
  final AnimationController shimmer;

  const _RewardCard({required this.card, required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: _rewardGradient(card.rewardType),
        boxShadow: [
          BoxShadow(
            color: _glowColor(card.rewardType).withAlpha(80),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            AnimatedBuilder(
              animation: shimmer,
              builder: (ctx, child) => Transform.scale(
                scale: 1 + 0.05 * math.sin(shimmer.value * math.pi * 2),
                child: child,
              ),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(20),
                  boxShadow: [
                    BoxShadow(
                      color: _glowColor(card.rewardType).withAlpha(120),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Icon(
                  _rewardIcon(card.rewardType),
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Reward type label
            Text(
              _rewardTypeLabel(card.rewardType),
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),

            // Main reward value
            Text(
              _rewardMainText(card),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Sub text
            if (_rewardSubText(card).isNotEmpty)
              Text(
                _rewardSubText(card),
                style: TextStyle(
                  color: Colors.white.withAlpha(180),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 20),

            // Challenge info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                card.challengeTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _rewardGradient(ScratchRewardType type) {
    switch (type) {
      case ScratchRewardType.xp:
        return const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ScratchRewardType.medal:
        return const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ScratchRewardType.badge:
        return const LinearGradient(
          colors: [Color(0xFF9B5DE5), Color(0xFF6C63FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ScratchRewardType.multiplier:
        return const LinearGradient(
          colors: [Color(0xFF00E5A0), Color(0xFF00BCA0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ScratchRewardType.nothing:
        return const LinearGradient(
          colors: [Color(0xFF2A2D3E), Color(0xFF1A1D2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _glowColor(ScratchRewardType type) {
    switch (type) {
      case ScratchRewardType.xp:
        return const Color(0xFF00B4DB);
      case ScratchRewardType.medal:
        return const Color(0xFFFFB300);
      case ScratchRewardType.badge:
        return const Color(0xFF9B5DE5);
      case ScratchRewardType.multiplier:
        return AppColors.primary;
      case ScratchRewardType.nothing:
        return Colors.white;
    }
  }

  IconData _rewardIcon(ScratchRewardType type) {
    switch (type) {
      case ScratchRewardType.xp:
        return Iconsax.flash;
      case ScratchRewardType.medal:
        return Iconsax.medal_star5;
      case ScratchRewardType.badge:
        return Iconsax.shield_tick;
      case ScratchRewardType.multiplier:
        return Iconsax.element_plus;
      case ScratchRewardType.nothing:
        return Iconsax.emoji_happy;
    }
  }

  String _rewardTypeLabel(ScratchRewardType type) {
    switch (type) {
      case ScratchRewardType.xp:
        return 'YOU EARNED';
      case ScratchRewardType.medal:
        return 'MEDAL UNLOCKED';
      case ScratchRewardType.badge:
        return 'BADGE EARNED';
      case ScratchRewardType.multiplier:
        return 'XP MULTIPLIER';
      case ScratchRewardType.nothing:
        return 'BETTER LUCK NEXT TIME';
    }
  }

  String _rewardMainText(ScratchCard card) {
    switch (card.rewardType) {
      case ScratchRewardType.xp:
        return '+${card.xpAmount} XP';
      case ScratchRewardType.medal:
        return card.medal?.label ?? 'Medal';
      case ScratchRewardType.badge:
        return card.badgeTitle ?? 'Explorer';
      case ScratchRewardType.multiplier:
        return '×${card.multiplier?.toStringAsFixed(1) ?? '2.0'}';
      case ScratchRewardType.nothing:
        return '😊';
    }
  }

  String _rewardSubText(ScratchCard card) {
    switch (card.rewardType) {
      case ScratchRewardType.xp:
        return 'Experience Points';
      case ScratchRewardType.medal:
        return 'Added to your medals';
      case ScratchRewardType.badge:
        return 'Badge unlocked';
      case ScratchRewardType.multiplier:
        return 'XP multiplier for next challenge';
      case ScratchRewardType.nothing:
        return 'Keep trying — great rewards await!';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _ScratchHintWidget extends StatelessWidget {
  final AnimationController shimmer;
  const _ScratchHintWidget({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.finger_cricle,
              size: 18,
              color: Colors.white.withAlpha(
                (120 + 100 * math.sin(shimmer.value * math.pi * 2)).round(),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Swipe across the card',
              style: TextStyle(
                color: Colors.white.withAlpha(
                  (100 + 100 * math.sin(shimmer.value * math.pi * 2)).round(),
                ),
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RewardDescription extends StatelessWidget {
  final ScratchCard card;
  const _RewardDescription({required this.card});

  @override
  Widget build(BuildContext context) {
    if (card.rewardType == ScratchRewardType.nothing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          "No reward this time — keep completing challenges for more chances!",
          style: TextStyle(color: Colors.white60, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(10),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.tick_circle,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _congratsText(card),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _congratsText(ScratchCard card) {
    switch (card.rewardType) {
      case ScratchRewardType.xp:
        return '+${card.xpAmount} XP has been added to your profile!';
      case ScratchRewardType.medal:
        return '${card.medal?.label ?? ''} medal saved to your collection!';
      case ScratchRewardType.badge:
        return '"${card.badgeTitle ?? ''}" badge earned!';
      case ScratchRewardType.multiplier:
        return '×${card.multiplier?.toStringAsFixed(1)} multiplier on your next challenge!';
      case ScratchRewardType.nothing:
        return '';
    }
  }
}
