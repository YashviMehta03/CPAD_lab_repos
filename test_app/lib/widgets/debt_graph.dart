import 'dart:math';
import 'package:flutter/material.dart';
import '../models/member_model.dart';
import '../services/debt_simplifier.dart';
import '../theme/app_theme.dart';

/// The animated debt graph widget — the hero feature.
/// Animates from raw debt edges to simplified edges on toggle.
class DebtGraph extends StatefulWidget {
  final List<Member> members;
  final Map<String, double> netBalances;
  final bool showSimplified;
  final List<Settlement> rawSettlements;
  final List<Settlement> simplifiedSettlements;

  const DebtGraph({
    super.key,
    required this.members,
    required this.netBalances,
    required this.showSimplified,
    required this.rawSettlements,
    required this.simplifiedSettlements,
  });

  @override
  State<DebtGraph> createState() => _DebtGraphState();
}

class _DebtGraphState extends State<DebtGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _lastSimplified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _lastSimplified = widget.showSimplified;
    if (widget.showSimplified) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(DebtGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSimplified != _lastSimplified) {
      _lastSimplified = widget.showSimplified;
      if (widget.showSimplified) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEdgeTap(BuildContext context, Settlement s) {
    final from = widget.members.firstWhere((m) => m.id == s.fromMemberId,
        orElse: () => Member(
            id: '', groupId: '', name: 'Unknown', colorHex: 'FFFFFF'));
    final to = widget.members.firstWhere((m) => m.id == s.toMemberId,
        orElse: () => Member(
            id: '', groupId: '', name: 'Unknown', colorHex: 'FFFFFF'));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _MemberAvatar(member: from, size: 48),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.arrow_forward,
                          color: AppTheme.negative),
                      Text(
                        '₹${s.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                _MemberAvatar(member: to, size: 48),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${from.name} owes ${to.name} ₹${s.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.members.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return GestureDetector(
          onTapUp: (details) {
            // Find tapped edge
            final size = context.size;
            if (size == null) return;
            final center = Offset(size.width / 2, size.height / 2);
            final radius = (size.width.clamp(0, size.height) / 2) * 0.65;

            final nodePositions = _calculateNodePositions(
                widget.members.length, center, radius);

            final rawEdges = _buildEdges(
                widget.rawSettlements, nodePositions, widget.members);
            final simplifiedEdges = _buildEdges(
                widget.simplifiedSettlements, nodePositions, widget.members);

            // Check simplified edges (shown when animation > 0.5)
            final edgesToCheck = _animation.value > 0.5
                ? simplifiedEdges
                : rawEdges;

            for (final edge in edgesToCheck) {
              if (_isNearEdge(details.localPosition, edge.from, edge.to)) {
                final settlement = _animation.value > 0.5
                    ? widget.simplifiedSettlements[
                        simplifiedEdges.indexOf(edge)]
                    : widget.rawSettlements[rawEdges.indexOf(edge)];
                _onEdgeTap(context, settlement);
                return;
              }
            }
          },
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _DebtGraphPainter(
              members: widget.members,
              rawSettlements: widget.rawSettlements,
              simplifiedSettlements: widget.simplifiedSettlements,
              animationValue: _animation.value,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  bool _isNearEdge(Offset tap, Offset from, Offset to) {
    // Check if tap is within ~20px of the line segment
    final d = _pointToSegmentDistance(tap, from, to);
    return d < 22;
  }

  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final lenSq = dx * dx + dy * dy;
    if (lenSq == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / lenSq;
    final tc = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + tc * dx, a.dy + tc * dy);
    return (p - proj).distance;
  }

  List<_Edge> _buildEdges(List<Settlement> settlements,
      List<Offset> nodePositions, List<Member> members) {
    return settlements.map((s) {
      final fromIdx =
          members.indexWhere((m) => m.id == s.fromMemberId);
      final toIdx = members.indexWhere((m) => m.id == s.toMemberId);
      if (fromIdx == -1 || toIdx == -1) return _Edge(Offset.zero, Offset.zero);
      return _Edge(nodePositions[fromIdx], nodePositions[toIdx]);
    }).toList();
  }

  List<Offset> _calculateNodePositions(
      int count, Offset center, double radius) {
    return List.generate(count, (i) {
      final angle = (2 * pi * i / count) - pi / 2;
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });
  }
}

class _Edge {
  final Offset from;
  final Offset to;
  _Edge(this.from, this.to);
}

class _DebtGraphPainter extends CustomPainter {
  final List<Member> members;
  final List<Settlement> rawSettlements;
  final List<Settlement> simplifiedSettlements;
  final double animationValue; // 0 = raw, 1 = simplified

  _DebtGraphPainter({
    required this.members,
    required this.rawSettlements,
    required this.simplifiedSettlements,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (members.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width.clamp(0.0, size.height) / 2) * 0.65;

    final nodePositions = _calculateNodePositions(members.length, center, radius);

    // Draw edges
    _drawEdges(canvas, nodePositions, rawSettlements, 1.0 - animationValue,
        isSimplified: false);
    _drawEdges(canvas, nodePositions, simplifiedSettlements, animationValue,
        isSimplified: true);

    // Draw nodes on top
    for (int i = 0; i < members.length; i++) {
      _drawNode(canvas, nodePositions[i], members[i]);
    }
  }

  List<Offset> _calculateNodePositions(
      int count, Offset center, double radius) {
    return List.generate(count, (i) {
      final angle = (2 * pi * i / count) - pi / 2;
      return Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
    });
  }

  void _drawEdges(Canvas canvas, List<Offset> nodePositions,
      List<Settlement> settlements, double opacity,
      {required bool isSimplified}) {
    if (opacity <= 0.01) return;

    final maxAmount = settlements.isEmpty
        ? 1.0
        : settlements.map((s) => s.amount).reduce(max);

    for (final s in settlements) {
      final fromIdx = members.indexWhere((m) => m.id == s.fromMemberId);
      final toIdx = members.indexWhere((m) => m.id == s.toMemberId);
      if (fromIdx == -1 || toIdx == -1) continue;

      final from = nodePositions[fromIdx];
      final to = nodePositions[toIdx];
      final thickness = ((s.amount / maxAmount) * 3.5 + 1.0).clamp(1.0, 5.0);

      final color = isSimplified
          ? AppTheme.positive.withOpacity(opacity * 0.85)
          : AppTheme.negative.withOpacity(opacity * 0.6);

      final paint = Paint()
        ..color = color
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Draw curved arrow
      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final perp = Offset(
        -(to.dy - from.dy) * 0.25,
        (to.dx - from.dx) * 0.25,
      );
      final control = mid + perp;

      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);

      canvas.drawPath(path, paint);

      // Arrowhead
      _drawArrowhead(canvas, control, to, color, thickness);

      // Amount label along the edge
      if (opacity > 0.4) {
        _drawAmountLabel(
            canvas, mid + perp * 0.5, '₹${s.amount.toStringAsFixed(0)}',
            opacity);
      }
    }
  }

  void _drawArrowhead(
      Canvas canvas, Offset from, Offset to, Color color, double thickness) {
    final angle = atan2(to.dy - from.dy, to.dx - from.dx);
    const arrowSize = 10.0;
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * cos(angle - 0.45),
      to.dy - arrowSize * sin(angle - 0.45),
    );
    path.lineTo(
      to.dx - arrowSize * cos(angle + 0.45),
      to.dy - arrowSize * sin(angle + 0.45),
    );
    path.close();
    canvas.drawPath(path, arrowPaint);
  }

  void _drawAmountLabel(Canvas canvas, Offset pos, String text, double opacity) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(opacity * 0.8),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Background pill
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: pos,
        width: textPainter.width + 10,
        height: textPainter.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color =
            AppTheme.bgDark.withOpacity(opacity * 0.8),
    );

    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  void _drawNode(Canvas canvas, Offset pos, Member member) {
    const nodeRadius = 26.0;
    final color = _hexToColor(member.colorHex);

    // Shadow
    canvas.drawCircle(
      pos + const Offset(0, 3),
      nodeRadius,
      Paint()
        ..color = Colors.black38
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Node fill
    canvas.drawCircle(pos, nodeRadius, Paint()..color = color.withOpacity(0.25));
    canvas.drawCircle(
      pos,
      nodeRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Initial text
    final initial = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';
    final textPainter = TextPainter(
      text: TextSpan(
        text: initial,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );

    // Name label below node
    final namePainter = TextPainter(
      text: TextSpan(
        text: member.name.split(' ').first,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 70);
    namePainter.paint(
      canvas,
      pos +
          Offset(
            -namePainter.width / 2,
            nodeRadius + 6,
          ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }

  @override
  bool shouldRepaint(_DebtGraphPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.members != members ||
        oldDelegate.rawSettlements != rawSettlements ||
        oldDelegate.simplifiedSettlements != simplifiedSettlements;
  }
}

class _MemberAvatar extends StatelessWidget {
  final Member member;
  final double size;

  const _MemberAvatar({required this.member, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = _hexToColor(member.colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          member.name[0].toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }

  Color _hexToColor(String hex) {
    try {
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primary;
    }
  }
}
