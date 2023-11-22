// Import the test package and Counter class
import 'dart:async';

import 'package:flutter_stockfish_plugin/stockfish.dart';
import 'package:flutter_test/flutter_test.dart';

///  To run the test, you have to
///    1. run the example (example/lib/main.dart) in windows,
///       so everything gets build
///    2. copy flutter_stockfish_plugin.dll to root-directory
///       (directly to flutter_stockfish_plugin) manually
void main() {
  test('Start Stockfish and uci init', () async {
    final fish1 = Stockfish();

    List<String> received = [];
    Completer readyCompleter = Completer();
    Completer uciOkCompleter = Completer();

    fish1.stdout.listen((event) {
      print(event);
      received.add(event);
      if (event == "uciok") {
        uciOkCompleter.complete();
      }
    });
    fish1.state.addListener(() {
      if (fish1.state.value.name == "ready") {
        readyCompleter.complete();
      } else if (fish1.state.value.name == "error") {
        readyCompleter.completeError("ERROR: CANNOT INIT STOCKFISH");
      }
    });

    // wait for stockfish startup
    await readyCompleter.future;

    // then init uci
    fish1.stdin = "uci";

    // then wait for uciok
    await uciOkCompleter.future;

    expect(received.last, "uciok");
  });
}
