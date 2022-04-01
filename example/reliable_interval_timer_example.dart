import 'package:reliable_interval_timer/reliable_interval_timer.dart';

const intervalInMilliseconds = 250;

int ticks = 0;

void main() {
  var timer = ReliableIntervalTimer(
    interval: Duration(milliseconds: intervalInMilliseconds),
    callback: onTimerTick,
  );

  timer.start().then((_) {
    print('Timer started');
  });
}

void onTimerTick(int elapsedMilliseconds) {
  ticks++;

  print('Tick #$ticks after $elapsedMilliseconds');
}
