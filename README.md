<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

A timer that produces ticks within a given interval, accurate to the millisecond.

## Features

`ReliableIntervalTimer` class provides you a periodic timer that has the exact same duration between ticks, accurate to the millisecond.
The timer is run inside an isolate.

## Usage

```dart
ReliableIntervalTimer(
    interval: Duration(milliseconds: 100),
    callback: (elapsedMilliseconds) => print('elapsedMilliseconds: $elapsedMilliseconds');,
);
```
