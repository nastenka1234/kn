import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tokens.dart';

/// نوتیف ژله‌ای درون‌برنامه؛ برای هر «امضا» فقط یک‌بار نشان داده می‌شود.
Future<void> jellyOnce(BuildContext context, String sig, String text,
    {IconData icon = Icons.edit_note_rounded}) async {
  try {
    final p = await SharedPreferences.getInstance();
    if (p.getString('jelly_sig') == sig) return;
    await p.setString('jelly_sig', sig);
  } catch (_) {}
  if (!context.mounted) return;
  showJelly(context, text, icon: icon);
}

void showJelly(BuildContext context, String text,
    {IconData icon = Icons.edit_note_rounded, Duration stay = const Duration(seconds: 4)}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _Jelly(text: text, icon: icon, stay: stay, onDone: () => entry.remove()),
  );
  overlay.insert(entry);
  HapticFeedback.mediumImpact();
}

class _Jelly extends StatefulWidget {
  final String text;
  final IconData icon;
  final Duration stay;
  final VoidCallback onDone;
  const _Jelly({required this.text, required this.icon, required this.stay, required this.onDone});

  @override
  State<_Jelly> createState() => _JellyState();
}

class _JellyState extends State<_Jelly> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  late final AnimationController _out =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _in.forward();
    Future.delayed(widget.stay, _close);
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    await _out.forward();
    widget.onDone();
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_in, _out]),
                  builder: (context, child) {
                    final s = Curves.elasticOut.transform(_in.value);
                    final o = Curves.easeInCubic.transform(_out.value);
                    final d = (s - 1).clamp(-.35, .35).toDouble();
                    final dy = -120 * (1 - s) - 150 * o;
                    final opacity = (_in.value * 5).clamp(0.0, 1.0).toDouble() * (1 - o);
                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: Transform(
                          alignment: Alignment.topCenter,
                          transform: Matrix4.diagonal3Values(1 - d * .28, 1 + d * .30, 1),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTap: _close,
                    onVerticalDragUpdate: (d) {
                      if (d.delta.dy < -4) _close();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(T.acc, Colors.white, .2)!, T.acc],
                        ),
                        boxShadow: [BoxShadow(color: T.acc.withOpacity(.45), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: Row(children: [
                        Icon(widget.icon, color: T.bg, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(widget.text,
                              style: TextStyle(color: T.bg, fontSize: 14, fontWeight: FontWeight.w800)),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
