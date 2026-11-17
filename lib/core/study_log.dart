import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'jalali.dart';

/// بازه‌های واقعی مطالعه (ساعت شروع و پایان) برای نمودار حرارتی ۲۴ ساعته.
/// فقط روی همین گوشی نگه داشته می‌شود. هر روز (به وقت تهران) فهرستی از [شروع، پایان]
/// بر حسب «ثانیه از نیمه‌شب» است و بازه‌های چسبیده یا هم‌پوشان یکی می‌شوند.
class StudyLog {
  static const _tzMs = 12600000; // +۰۳:۳۰
  static const _dayMs = 86400000;
  static const keepDays = 120;

  static String _k(String day) => 'studylog:${Api.i.sid ?? '_'}:$day';

  static Future<void> _tail = Future.value(); // ثبت‌ها پشت‌سرهم، تا چیزی گم نشود

  /// بازه‌های [startMs, endMs] (epoch) را روی روزهای تهران پخش و ذخیره می‌کند.
  static Future<void> add(List<(int, int)> spans) {
    if (spans.isEmpty) return Future.value();
    _tail = _tail.then((_) => _add(spans)).catchError((_) {});
    return _tail;
  }

  static Future<void> _add(List<(int, int)> spans) async {
    final p = await SharedPreferences.getInstance();
    final perDay = <String, List<List<int>>>{};
    for (final sp in spans) {
      var a = sp.$1 + _tzMs, b = sp.$2 + _tzMs;
      if (b - a < 1000) continue;
      while (a < b) {
        final di = a ~/ _dayMs;
        final end = b < (di + 1) * _dayMs ? b : (di + 1) * _dayMs;
        final day = isoDay(DateTime.fromMillisecondsSinceEpoch(di * _dayMs, isUtc: true));
        (perDay[day] ??= []).add([(a - di * _dayMs) ~/ 1000, (end - di * _dayMs) ~/ 1000]);
        a = end;
      }
    }
    for (final e in perDay.entries) {
      final cur = await _read(p, e.key);
      await p.setString(_k(e.key), jsonEncode(_merge([...cur, ...e.value])));
    }
    // قدیمی‌ها را پاک کن (کم‌هزینه: فقط یک بار در هر ثبت، روی کلیدهای این حساب)
    final cutoff = addDays(todayIso(), -keepDays);
    final pre = 'studylog:${Api.i.sid ?? '_'}:';
    for (final k in p.getKeys()) {
      if (k.startsWith(pre) && k.substring(pre.length).compareTo(cutoff) < 0) await p.remove(k);
    }
  }

  static List<List<int>> _merge(List<List<int>> v) {
    if (v.isEmpty) return v;
    v.sort((x, y) => x[0].compareTo(y[0]));
    final out = <List<int>>[List<int>.of(v.first)];
    for (final s in v.skip(1)) {
      if (s[0] <= out.last[1] + 30) {
        if (s[1] > out.last[1]) out.last[1] = s[1];
      } else {
        out.add(List<int>.of(s));
      }
    }
    return out;
  }

  static Future<List<List<int>>> _read(SharedPreferences p, String day) async {
    try {
      final raw = p.getString(_k(day));
      if (raw == null) return [];
      return [for (final x in jsonDecode(raw) as List) [(x[0] as num).toInt(), (x[1] as num).toInt()]];
    } catch (_) {
      return [];
    }
  }

  /// بازه‌های یک روز (ثانیه از نیمه‌شب).
  static Future<List<List<int>>> day(String iso) async => _read(await SharedPreferences.getInstance(), iso);

  /// بازه‌های [days] روز آخر تا امروز؛ قدیمی‌ترین اول.
  static Future<Map<String, List<List<int>>>> range(int days) async {
    final p = await SharedPreferences.getInstance();
    final today = todayIso();
    final out = <String, List<List<int>>>{};
    for (var i = days - 1; i >= 0; i--) {
      final d = addDays(today, -i);
      out[d] = await _read(p, d);
    }
    return out;
  }
}
