import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';
import 'package:flutter_stockfish_plugin/stockfish_native_bindings.dart'
    if (dart.library.html) 'package:flutter_stockfish_plugin/stockfish_web_bindings.dart';
import 'package:flutter_stockfish_plugin/stockfish_state.dart';

class Stockfish {
  final _state = StockfishStateClass();
  final StockfishChessEngineAbstractBindings _bindings =
      StockfishChessEngineBindings();

  Stockfish._({Completer<Stockfish>? completer}) {
    _state.setValue(StockfishState.starting);
    _bindings.stockfishMain(() {
      _state.setValue(StockfishState.ready);
      completer?.complete(this);
    }).then((exitCode) {
      _state.setValue(
          exitCode == 0 ? StockfishState.disposed : StockfishState.error);
      _instance = null;
    }, onError: (error) {
      _state.setValue(StockfishState.error);
      _instance = null;
      completer?.completeError(error);
    });
  }

  static Stockfish? _instance;

  /// Creates the stockfish engine.
  ///
  /// This may throws a [StateError] if an active instance is being used.
  /// Owner must [dispose] it before a new instance can be created.
  factory Stockfish() {
    if (_instance != null) {
      throw StateError('Multiple instances are not supported, yet.');
    }
    _instance = Stockfish._();
    return _instance!;
  }

  /// The current state of the underlying stockfish engine.
  ValueListenable<StockfishState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _bindings.read;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = state.value;
    if (stateValue != StockfishState.ready) {
      throw StateError('Stockfish is not ready ($stateValue)');
    }
    _bindings.write(line);
  }

  /// Stops the stockfish engine.
  void dispose() {
    final stateValue = state.value;
    if (stateValue == StockfishState.ready) {
      stdin = 'quit';
    }
  }
}

/// Creates the stockfish engine asynchronously.
///
/// This method is different from the factory method [Stockfish] that
/// it will wait for the engine to be ready before returning the instance.
Future<Stockfish> stockfishAsync() {
  if (Stockfish._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<Stockfish>();
  Stockfish._instance = Stockfish._(completer: completer);
  return completer.future;
}
