import 'package:flutter/foundation.dart';
import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';
import 'package:flutter_stockfish_plugin/stockfish_native_bindings.dart'
    if (dart.library.html) 'package:flutter_stockfish_plugin/stockfish_web_bindings.dart';
import 'package:flutter_stockfish_plugin/stockfish_state.dart';

final StockfishChessEngineAbstractBindings _bindings =
    StockfishChessEngineBindings();

class Stockfish {
  final _state = StockfishStateClass();

  Stockfish._() {
    _state.setValue(StockfishState.starting);
    _bindings.stockfishMain(() {
      _state.setValue(StockfishState.ready);
    }).then((exitCode) {
      _state.setValue(
          exitCode == 0 ? StockfishState.disposed : StockfishState.error);
      _instance = null;
    }, onError: (error) {
      _state.setValue(StockfishState.error);
      _instance = null;
    });
  }

  static Stockfish? _instance;

  /// Creates a C++ engine.
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

  /// The current state of the underlying C++ engine.
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

  /// Stops the C++ engine.
  void dispose() {
    final stateValue = state.value;
    if (stateValue == StockfishState.ready) {
      stdin = 'quit';
    }
  }

  void _cleanUp(int exitCode) {
    /*_stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();

    _state._setValue(
        exitCode == 0 ? StockfishState.disposed : StockfishState.error);

    _instance = null;*/
  }
}
