import 'dart:async';

import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';

class StockfishChessEngineBindings
    extends StockfishChessEngineAbstractBindings {
  @override
  void cleanUp(int exitCode) {
    // TODO: implement cleanUp
  }

  @override
  Future<int> stockfishMain(Function active) {
    // TODO: implement stockfishMain
    final completer = Completer<int>();
    //completer.complete(0);
    active();
    return completer.future;
  }

  @override
  void write(String line) {
    // TODO: implement write
  }
}
