import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../theme/tokens.dart';

class DockItem {
  final String label;
  final IconData icon;
  const DockItem(this.label, this.icon);
}

/// نوار پایین شناور با «مهره»ی لغزنده (طبق ویدیوی مرجع):
/// مهره در شیاری روی لبه‌ی بالای نوار می‌نشیند، با فنر به تب انتخابی می‌لغزد،
/// با انگشت هم قابل کشیدن است. رنگ‌ها همان پالت نارنجی برنامه است.
class DockNav extends StatefulWidget {
  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onSelected;
  const DockNav({super.key, required this.items, required this.index, required this.onSelected});

  @override
  State<DockNav> createState() => _DockNavState();
}

class _DockNavState extends State<DockNav> with SingleTickerProviderStateMixin {
  static const double _bar = 66; // ارتفاع بدنه‌ی نوار
  static const double _over = 26; // مقدار بیرون‌زدگی مهره از بالای نوار
  static const double _r = 25; // شعاع مهره
  static const double _gap = 4; // فاصله‌ی شیار تا مهره
  static const double _edge = _r + _gap + 8 + 22; // کمترین فاصله‌ی مرکز شیار از لبه

  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.index.toDouble());
  bool _dragging = false;
  late int _shown = widget.index; // تب نمایش‌داده‌شده زیر مهره (برای برچسب و لرزش)

  int get _n => widget.items.length;

  @override
  void didUpdateWidget(covariant DockNav old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _shown = widget.index;
      if (!_dragging) _springTo(widget.index);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _springTo(int i) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = i.toDouble();
      return;
    }
    _c.animateWith(SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 260, damping: 19),
      _c.value,
      i.toDouble(),
      _c.velocity,
    ));
  }

  // مرکز تب‌ها به‌صورت خطی از _edge تا w-_edge پخش می‌شوند؛ پس مرکز آیکن هر تب، مرکز شیار و
  // مرکز مهره دقیقاً یک نقطه‌اند (بدون clamp جدا برای لبه‌ها). RTL: تب اول سمت راست.
  double _step(double w) => (w - 2 * _edge) / math.max(1, _n - 1);

  double _cxRaw(double p, double w, bool rtl) =>
      rtl ? w - _edge - p * _step(w) : _edge + p * _step(w);

  double _cx(double pos, double w, bool rtl) =>
      _cxRaw(pos.clamp(0.0, _n - 1.0).toDouble(), w, rtl);

  double _posFromX(double x, double w, bool rtl) {
    final px = rtl ? (w - _edge - x) : (x - _edge);
    return (px / _step(w)).clamp(0.0, _n - 1.0).toDouble();
  }

  void _select(int i) {
    if (i != _shown) HapticFeedback.selectionClick();
    _shown = i;
    widget.onSelected(i);
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 0, 14, math.max(bottom, 8) + 4),
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        return SizedBox(
          height: _bar + _over,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _select(_posFromX(d.localPosition.dx, w, rtl).round()),
            onHorizontalDragStart: (d) {
              _dragging = true;
              _c.stop();
            },
            onHorizontalDragUpdate: (d) {
              _c.value = _posFromX(d.localPosition.dx, w, rtl);
              final near = _c.value.round();
              if (near != _shown) {
                HapticFeedback.selectionClick();
                _shown = near;
              }
            },
            onHorizontalDragEnd: (_) {
              _dragging = false;
              final i = _c.value.round();
              _springTo(i);
              _select(i);
            },
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final pos = _c.value;
                final cx = _cx(pos, w, rtl);
                final active = pos.round().clamp(0, _n - 1).toInt();
                return Stack(clipBehavior: Clip.none, children: [
                  // درخشش رنگی زیر نوار
                  Positioned(
                    left: cx - 70,
                    top: _over + _bar - 14,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [BoxShadow(color: T.acc.withOpacity(.32), blurRadius: 36, spreadRadius: 2)],
                        ),
                      ),
                    ),
                  ),
                  // بدنه + شیار
                  Positioned.fill(
                    top: _over, // لبه‌ی بالای بدنه
                    child: CustomPaint(
                      painter: _DockPainter(cx: cx, r: _r + _gap, f: 8),
                    ),
                  ),
                  // آیکن‌های تب‌های غیرفعال (هر کدام دقیقاً در مرکز تب خودش)
                  for (var i = 0; i < _n; i++)
                    Positioned(
                      left: _cxRaw(i.toDouble(), w, rtl) - 12,
                      top: _over + 6,
                      child: IgnorePointer(
                        child: Opacity(
                          // هرچه مهره نزدیک‌تر، آیکن محو‌تر؛ زیر مهره آیکن خود مهره دیده می‌شود
                          opacity: ((pos - i).abs() - .15).clamp(0.0, 1.0).toDouble(),
                          child: Icon(widget.items[i].icon, size: 24, color: T.tx2),
                        ),
                      ),
                    ),
                  Positioned(
                    left: cx - 50,
                    width: 100,
                    top: _over + 38,
                    child: IgnorePointer(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          widget.items[active].label,
                          key: ValueKey(active),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: T.acc, fontSize: 11.5, fontWeight: FontWeight.w700, height: 1.2),
                        ),
                      ),
                    ),
                  ),
                  // مهره
                  Positioned(
                    left: cx - _r,
                    top: _over - _r + 8, // مرکز مهره هم‌مرکز قوس شیار (f = 8)
                    child: IgnorePointer(
                      child: Container(
                        width: _r * 2,
                        height: _r * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color.lerp(T.acc, Colors.white, .2)!, T.acc],
                          ),
                          boxShadow: [BoxShadow(color: T.acc.withOpacity(.55), blurRadius: 20)],
                        ),
                        child: Icon(widget.items[active].icon, size: 25, color: T.onAcc),
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        );
      }),
    );
  }
}

/// بدنه‌ی نوار با شیار نیم‌دایره‌ای نرم در لبه‌ی بالا.
class _DockPainter extends CustomPainter {
  final double cx, r, f;
  _DockPainter({required this.cx, required this.r, required this.f});

  Path _path(Size s) {
    const rad = 22.0;
    final w = s.width, h = s.height;
    final c = cx.clamp(r + f + rad, w - r - f - rad).toDouble();
    final p = Path()..moveTo(rad, 0);
    p.lineTo(c - r - f, 0);
    p.quadraticBezierTo(c - r, 0, c - r, f); // گوشه‌ی نرم ورودی شیار
    p.arcTo(Rect.fromCircle(center: Offset(c, f), radius: r), math.pi, -math.pi, false); // کف شیار
    p.quadraticBezierTo(c + r, 0, c + r + f, 0); // گوشه‌ی نرم خروجی
    p.lineTo(w - rad, 0);
    p.arcToPoint(Offset(w, rad), radius: const Radius.circular(rad));
    p.lineTo(w, h - rad);
    p.arcToPoint(Offset(w - rad, h), radius: const Radius.circular(rad));
    p.lineTo(rad, h);
    p.arcToPoint(Offset(0, h - rad), radius: const Radius.circular(rad));
    p.lineTo(0, rad);
    p.arcToPoint(const Offset(rad, 0), radius: const Radius.circular(rad));
    p.close();
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _path(size);
    canvas.drawShadow(path, Colors.black, 10, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [T.surfaceHi, T.sec],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = T.line2,
    );
  }

  @override
  bool shouldRepaint(covariant _DockPainter o) => o.cx != cx || o.r != r || o.f != f;
}
