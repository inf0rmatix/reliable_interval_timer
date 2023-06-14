import 'dart:async';
import 'dart:isolate';

class ReliableIntervalTimer {
  static const _isolateTimerDurationMicroseconds = 500;

  /// Specifies the time that should lie in between execution of [callback].
  /// Must not be smaller then one millisecond. This value can be updated with updateInterval() method.
  Duration interval;

  /// The function is passed [elapsedMilliseconds] after the last tick and executed once every [interval].
  final Function(int elapsedMilliseconds) callback;

  Isolate? _isolate;
  StreamSubscription? _isolateSubscription;

  /// The port to send updates for tick rate to the isolate.
  SendPort? _tickRateUpdatePort;

  bool _isWarmingUp = true;
  bool _isReady = false;

  int _millisecondsLastTick = -1;

  ReliableIntervalTimer({
    required this.interval,
    required this.callback,
  }) : assert(interval.inMilliseconds > 0,
            'Intervals smaller than a millisecond are not supported');

  /// Checks if the timer is running
  bool get isRunning => _isolate != null;

  /// Starts the timer, the future completes once the timer completed the first accurate interval.
  Future<void> start() async {
    if (_isolate != null) {
      throw Exception(
          'Timer is already running! Use stop() to stop it before restarting.');
    }

    var completer = Completer();
    var receivePort = ReceivePort();

    _isolate = await Isolate.spawn(
      _isolateTimer,
      {
        'tickRate': interval.inMilliseconds,
        'sendToMainThreadPort': receivePort.sendPort,
      },
    );

    _isolateSubscription = receivePort.listen((message) {
      if (message is SendPort) {
        _tickRateUpdatePort = message;
      } else {
        _onIsolateTimerTick(completer);
      }
    });

    return completer.future;
  }

  /// Stops the timer, canceling the subscription and killing the isolate.
  Future<void> stop() async {
    await _isolateSubscription?.cancel();
    _isolateSubscription = null;

    _isolate?.kill();
    _isolate = null;
    _tickRateUpdatePort = null;
  }

  /// Updates the timer interval, allowing the timer interval to be changed without spawning another isolate.
  Future<void> updateInterval(Duration newInterval) async {
    interval = newInterval;
    _tickRateUpdatePort?.send(newInterval.inMilliseconds);
  }

  void _onIsolateTimerTick(Completer completer) {
    var now = DateTime.now().millisecondsSinceEpoch;

    var elapsedMilliseconds = (now - _millisecondsLastTick).abs();

    _millisecondsLastTick = now;

    if (_isWarmingUp) {
      _isReady = elapsedMilliseconds == interval.inMilliseconds;
      _isWarmingUp = !_isReady;

      if (_isReady) completer.complete();
    } else {
      callback(elapsedMilliseconds);
    }
  }

  static Future<void> _isolateTimer(Map data) async {
    int tickRate = data['tickRate'];
    SendPort sendToMainThreadPort = data['sendToMainThreadPort'];

    var updatePort = ReceivePort();
    sendToMainThreadPort.send(updatePort.sendPort);

    updatePort.listen((newTickRate) {
      if (newTickRate is int) {
        tickRate = newTickRate;
      }
    });

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
