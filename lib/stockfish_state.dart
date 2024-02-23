import 'package:flutter/foundation.dart';

class StockfishStateClass extends ChangeNotifier
    implements ValueListenable<StockfishState> {
  StockfishState _value = StockfishState.starting;

  @override
  StockfishState get value => _value;

  setValue(StockfishState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

// The following is taken from https://github.com/ArjanAswal/Stockfish/blob/master/lib/src/stockfish_state.dart

/// C++ engine state.
enum StockfishState {
  /// Engine has been stopped.
  disposed,

  /// An error occured (engine could not start).
  error,

  /// Engine is running.
  ready,

  /// Engine is starting.
  starting,
}
