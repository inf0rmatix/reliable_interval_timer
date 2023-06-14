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
      List<String> inAccurateTickInfos = [];

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
            var deviation = (duration - interval).abs();
            overallDeviation += deviation;

            inAccurateTickInfos.add('Tick #$ticksOverall deviated by $deviation ms');
          }

          if (ticksOverall == targetTicks) {
            completer.complete();
          }
        },
      );

      await timer.start();

      await completer.future;

      await timer.stop();

      for (String text in inAccurateTickInfos) {
        print(text);
      }

      print('Inaccurate ticks $inAccurateTicks');

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

    test('should update interval and provide ticks without any deviation', () async {
      const targetTicks = 100;
      const initialInterval = 10;
      const updatedInterval = 20;

      var ticksOverall = -1;
      var inaccurateTicks = 0;
      double overallDeviation = 0;
      int millisLastTick = 0;
      List<String> inaccurateTickInfos = [];

      var completer = Completer();

      // Declare the timer variable first.
      ReliableIntervalTimer? timer;

      // Define the callback.
      Future callback(int elapsed) async {
        if (ticksOverall >= targetTicks) {
          return;
        }

        ticksOverall++;

        if (ticksOverall == 10) {
          await timer!.updateInterval(Duration(milliseconds: updatedInterval));
        }

        var now = DateTime.now().millisecondsSinceEpoch;
        var duration = now - millisLastTick;
        millisLastTick = now;

        var expectedInterval = ticksOverall <= 10 ? initialInterval : updatedInterval;

        if (duration != expectedInterval && ticksOverall > 0) {
          inaccurateTicks++;
          var deviation = (duration - expectedInterval).abs();
          overallDeviation += deviation;

          inaccurateTickInfos.add('Tick #$ticksOverall deviated by $deviation ms');
        }

        if (ticksOverall == targetTicks) {
          completer.complete();
        }
      }

      // Now that the callback is defined, initialize the timer.
      timer = ReliableIntervalTimer(
        interval: Duration(milliseconds: initialInterval),
        callback: callback,
      );

      await timer.start();
      await completer.future;
      await timer.stop();

      for (String text in inaccurateTickInfos) {
        print(text);
      }

      print('Inaccurate ticks $inaccurateTicks');

      expect(inaccurateTicks, isZero);
      expect(overallDeviation, isZero);
      expect(ticksOverall, equals(targetTicks));
    });
  });
}
