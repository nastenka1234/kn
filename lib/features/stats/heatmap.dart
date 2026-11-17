import 'package:flutter/material.dart';
import '../../core/jalali.dart';
import '../../core/study_log.dart';
import '../../theme/glass.dart';
import '../../theme/tokens.dart';

/// نمودار حرارتی مطالعه: هر روز یک ردیف با ۲۴ بلاک (ساعت ۰ تا ۲۳).
/// هر بلاک دقیقاً به اندازه‌ی کسری از ساعت که مطالعه شده پر می‌شود و از همان نقطه‌ی شروع
/// (مثلاً مطالعه از دقیقه‌ی ۳۰ = نیمه‌ی راستِ بلاک). بلاک خالی = آن ساعت مطالعه نشده.
/// داده از ثبت محلی تایمر اتاق تمرکز می‌آید (فقط روی همین گوشی).
class StudyHeatmap extends StatefulWidget {
  final int range; // تعداد روز
  const StudyHeatmap({super.key, required this.range});
  @override
  State<StudyHeatmap> createState() => _StudyHeatmapState();
}

class _StudyHeatmapState extends State<StudyHeatmap> {
  Map<String, List<List<int>>> data = {};
  bool loading = true;
  String? picked;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant StudyHeatmap old) {
    super.didUpdateWidget(old);
    if (old.range != widget.range) _load();
  }

  Future<void> _load() async {
    final d = await StudyLog.range(widget.range);
    if (!mounted) return;
    setState(() {
      data = d;
      loading = false;
    });
  }

  static String _hm(int sec) {
    final h = sec ~/ 3600, m = (sec % 3600) ~/ 60;
    return fa('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
  }

  @override
  Widget build(BuildContext context) {
    final days = data.keys.toList().reversed.toList(); // امروز بالا
    final any = data.values.any((v) => v.isNotEmpty);
    final rowH = days.length > 31 ? 13.0 : 18.0;
    return Glass(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('نمودار حرارتی ساعت‌های مطالعه', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text('هر ردیف یک روز، هر بلاک یک ساعت', style: TextStyle(color: T.tx2, fontSize: 12)),
        const SizedBox(height: 12),
        if (loading)
          const SizedBox(height: 60)
        else ...[
          // محور ساعت (LTR: ساعت ۰ چپ، ۲۳ راست)
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: LayoutBuilder(builder: (context, box) {
                    final cw = box.maxWidth / 24;
                    return SizedBox(
                      height: 14,
                      child: Stack(children: [
                        for (final h in const [0, 3, 6, 9, 12, 15, 18, 21])
                          Positioned(
                            left: h * cw,
                            child: Text(fa(h), style: TextStyle(color: T.tx2, fontSize: 9.5)),
                          ),
                      ]),
                    );
                  }),
                ),
                const SizedBox(width: 6),
                const SizedBox(width: 44),
              ]),
              const SizedBox(height: 4),
              for (final d in days)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => picked = picked == d ? null : d),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(children: [
                      Expanded(
                        child: SizedBox(
                          height: rowH,
                          child: CustomPaint(
                            painter: _RowPainter(
                              data[d] ?? const [],
                              now: d == todayIso() ? _nowSec() : null,
                              selected: picked == d,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 44,
                        child: Text(
                          jalaliShort(d),
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                              color: picked == d ? T.acc : T.tx2, fontSize: rowH < 14 ? 8.5 : 10),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ]),
                  ),
                ),
            ]),
          ),
          if (!any)
            Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('هنوز مطالعه‌ای با تایمر ثبت نشده. بعد از اولین جلسه‌ی اتاق تمرکز اینجا پر می‌شود.',
                  style: TextStyle(color: T.tx2, fontSize: 12)),
            ),
          if (picked != null) ...[
            const SizedBox(height: 10),
            _detail(picked!),
          ],
        ],
      ]),
    );
  }

  static int _nowSec() {
    final n = tehranNow();
    return n.hour * 3600 + n.minute * 60 + n.second;
  }

  Widget _detail(String d) {
    final spans = data[d] ?? const <List<int>>[];
    final total = spans.fold<int>(0, (a, s) => a + (s[1] - s[0]));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: T.bg.withOpacity(.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${jalaliFull(d)} — ${spans.isEmpty ? 'مطالعه‌ای ثبت نشده' : fmtMin(total / 60)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        if (spans.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final s in spans)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: T.glass, borderRadius: BorderRadius.circular(20)),
                child: Text('${_hm(s[0])} تا ${_hm(s[1])}', style: const TextStyle(fontSize: 11.5)),
              ),
          ]),
        ],
      ]),
    );
  }
}

class _RowPainter extends CustomPainter {
  final List<List<int>> spans; // ثانیه از نیمه‌شب
  final int? now; // فقط برای امروز: ساعت‌های آینده کم‌رنگ‌تر
  final bool selected;
  _RowPainter(this.spans, {this.now, this.selected = false});

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.5;
    final cw = size.width / 24;
    final empty = Paint()..color = T.glass.withOpacity(.55);
    final future = Paint()..color = T.glass.withOpacity(.22);
    final fill = Paint()..color = T.acc;
    final rr = Radius.circular(size.height > 15 ? 3.5 : 2.5);
    for (var h = 0; h < 24; h++) {
      final x0 = h * cw + gap / 2, x1 = (h + 1) * cw - gap / 2;
      final cell = RRect.fromLTRBAndCorners(x0, 0, x1, size.height,
          topLeft: rr, topRight: rr, bottomLeft: rr, bottomRight: rr);
      final isFuture = now != null && h * 3600 > now!;
      canvas.drawRRect(cell, isFuture ? future : empty);
      // کسر پرشده‌ی این ساعت، از همان نقطه‌ی واقعی شروع
      canvas.save();
      canvas.clipRRect(cell);
      for (final s in spans) {
        final a = (s[0] - h * 3600).clamp(0, 3600), b = (s[1] - h * 3600).clamp(0, 3600);
        if (b <= a) continue;
        final w = x1 - x0;
        canvas.drawRect(Rect.fromLTRB(x0 + a / 3600 * w, 0, x0 + b / 3600 * w, size.height), fill);
      }
      canvas.restore();
    }
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = T.hi.withOpacity(.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RowPainter o) => o.spans != spans || o.now != now || o.selected != selected;
}
