import 'dart:async';
import 'dart:isolate';

class ReliableIntervalTimer {
  static const _isolateTimerDurationMicroseconds = 500;

  final Duration intervall;
  final Function callback;

  Isolate? _isolate;
  StreamSubscription? _isolateSubscription;

  ReliableIntervalTimer({
    required this.intervall,
    required this.callback,
  }) : assert(intervall.inMilliseconds > 0, 'Intervals smaller than a millisecond are not supported');

  Future<void> start() async {
    if (_isolate != null) {
      throw Exception('Timer is already running! Use stop() the stop it before restarting.');
    }

    ReceivePort receiveFromIsolatePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateTimer,
      {
        'tickRate': intervall.inMilliseconds,
        'sendToMainThreadPort': receiveFromIsolatePort.sendPort,
      },
    );

    _isolateSubscription = receiveFromIsolatePort.listen((_) {
      callback();
    });
  }

  Future<void> stop() async {
    await _isolateSubscription?.cancel();
    _isolateSubscription = null;

    _isolate?.kill();
    _isolate = null;
  }

  static Future<void> _isolateTimer(Map data) async {
    int tickRate = data['tickRate'];
    SendPort sendToMainThreadPort = data['sendToMainThreadPort'];

    var millisLastTick = DateTime.now().millisecondsSinceEpoch;

    Timer.periodic(
      const Duration(microseconds: _isolateTimerDurationMicroseconds),
      (_) {
        var now = DateTime.now().millisecondsSinceEpoch;
        var duration = now - millisLastTick;

        if (duration >= tickRate) {
          sendToMainThreadPort.send(null);
          millisLastTick = now;
        }
      },
    );
  }
}
