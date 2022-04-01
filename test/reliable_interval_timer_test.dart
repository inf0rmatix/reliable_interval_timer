import 'dart:async';

import 'package:reliable_interval_timer/reliable_interval_timer.dart';
import 'package:test/test.dart';

void main() {
  group('Reliable Interval Timer', () {
    test('should provide ticks without any deviation', () async {
      const targetTicks = 100;
      const interval = 10;

      // defaults to -1, since there is natural delay between starting the timer or isolate and it's first tick
      var ticksOverall = -1;
      var inAccurateTicks = 0;
      double overallDeviation = 0;
      int millisLastTick = 0;

      var completer = Completer();

      var timer = ReliableIntervalTimer(
        interval: Duration(milliseconds: interval),
        callback: (elapsed) {
          if (ticksOverall >= targetTicks) {
            return;
          }

          ticksOverall++;

          var now = DateTime.now().millisecondsSinceEpoch;
          var duration = now - millisLastTick;
          millisLastTick = now;

          if (duration != interval && ticksOverall > 0) {
            inAccurateTicks++;
            overallDeviation += (duration - interval).abs();
          }

          if (ticksOverall == targetTicks) {
            completer.complete();
          }
        },
      );

      await timer.start();

      await completer.future;

      await timer.stop();

      expect(inAccurateTicks, isZero);
      expect(overallDeviation, isZero);
      expect(ticksOverall, equals(targetTicks));
    });

    test('should deny intervals smaller than a millisecond', () {
      ReliableIntervalTimer? timer;

      try {
        timer = ReliableIntervalTimer(interval: Duration(microseconds: 900), callback: (_) {});
      } catch (_) {
        // ignored
      }

      expect(timer, isNull);
    });
  });
}
