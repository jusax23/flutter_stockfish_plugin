// Using code from https://github.com/ArjanAswal/Stockfish/blob/master/lib/src/stockfish.dart

/// https://pub.dev/packages/thread/example

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

import 'stockfish_bindings_generated.dart';
import 'stockfish_state.dart';

const String _libName = 'flutter_stockfish_plugin';
//const String _releaseType = kDebugMode ? 'Debug' : 'Release';

/// A wrapper for C++ engine.
class Stockfish {
  /// The dynamic library in which the symbols for [StockfishChessEngineBindings] can be found.
  late final DynamicLibrary _dylib;

  /// The bindings to the native functions in [_dylib].
  late final StockfishChessEngineBindings _bindings;

  final Completer<Stockfish>? completer;

  final _StockfishState _state = _StockfishState();
  final _stdoutController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  Stockfish._({this.completer}) {
    print("1");
    _dylib = () {
      if (Platform.isMacOS || Platform.isIOS) {
        return DynamicLibrary.open('$_libName.framework/$_libName');
      }
      if (Platform.isAndroid || Platform.isLinux) {
        return DynamicLibrary.open('lib$_libName.so');
      }
      if (Platform.isWindows) {
        return DynamicLibrary.open('$_libName.dll');
      }
      throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
    }();
    _bindings = StockfishChessEngineBindings(_dylib);
    print("2");

    _mainSubscription =
        _mainPort.listen((message) => _cleanUp(message is int ? message : 1));
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else {
        developer.log('The stdout isolate sent $message', name: 'Stockfish');
      }
    });
    print("3");
    compute(_spawnIsolates,
        [_bindings, _mainPort.sendPort, _stdoutPort.sendPort]).then(
      (success) {
        print("4");

        final state = success ? StockfishState.ready : StockfishState.error;
        _state._setValue(state);
        if (state == StockfishState.ready) {
          completer?.complete(this);
        }
      },
      onError: (error) {
        print("5");
        print(error);

        developer.log('The init isolate encountered an error $error',
            name: 'Stockfish');
        _cleanUp(1);
      },
    );
  }

  static Stockfish? _instance;

  /// Creates a C++ engine.
  ///
  /// This may throws a [StateError] if an active instance is being used.
  /// Owner must [dispose] it before a new instance can be created.
  factory Stockfish() {
    /*if (_instance != null) {
      throw StateError('Multiple instances are not supported, yet.');
    }

    _instance = Stockfish._();
    return _instance!;*/
    return Stockfish._();
  }

  /// The current state of the underlying C++ engine.
  ValueListenable<StockfishState> get state => _state;

  /// The standard output stream.
  Stream<String> get stdout => _stdoutController.stream;

  /// The standard input sink.
  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != StockfishState.ready) {
      throw StateError('Stockfish is not ready ($stateValue)');
    }

    final unicodePointer = '$line\n'.toNativeUtf8();
    final pointer = unicodePointer.cast<Char>();
    _bindings.stockfish_stdin_write(pointer);
    calloc.free(unicodePointer);
  }

  /// Stops the C++ engine.
  void dispose() {
    final stateValue = _state.value;
    if (stateValue == StockfishState.ready) {
      stdin = 'quit';
    }
  }

  void _cleanUp(int exitCode) {
    _stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();

    _state._setValue(
        exitCode == 0 ? StockfishState.disposed : StockfishState.error);

    _instance = null;
  }
}

/// Creates a C++ engine asynchronously.
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

class _StockfishState extends ChangeNotifier
    implements ValueListenable<StockfishState> {
  StockfishState _value = StockfishState.starting;

  @override
  StockfishState get value => _value;

  _setValue(StockfishState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(List<dynamic> args) {
  StockfishChessEngineBindings bindings =
      args[0] as StockfishChessEngineBindings;
  SendPort mainPort = args[1] as SendPort;

  print("****************");
  final exitCode = bindings.stockfish_main();
  mainPort.send(exitCode);

  developer.log('nativeMain returns $exitCode', name: 'Stockfish');
}

void _isolateStdout(List args) {
  StockfishChessEngineBindings bindings =
      args[0] as StockfishChessEngineBindings;
  SendPort stdoutPort = args[1] as SendPort;

  String previous = '';

  while (true) {
    final pointer = bindings.stockfish_stdout_read();

    if (pointer.address == 0) {
      developer.log('nativeStdoutRead returns NULL', name: 'Stockfish');
      return;
    }

    Uint8List newContentCharList;

    final newContentLength = pointer.cast<Utf8>().length;
    newContentCharList = Uint8List.view(
        pointer.cast<Uint8>().asTypedList(newContentLength).buffer,
        0,
        newContentLength);

    final newContent = utf8.decode(newContentCharList);

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<dynamic> mainAndStdout) async {
  print("6");
  StockfishChessEngineBindings bindings =
      mainAndStdout[0] as StockfishChessEngineBindings;
  final initResult = bindings.stockfish_init();
  if (initResult != 0) {
    developer.log('initResult=$initResult', name: 'Stockfish');
    return false;
  }

  try {
    print("7");
    await Isolate.spawn(
        _isolateStdout, [bindings, mainAndStdout[2] as SendPort]);
  } catch (error) {
    developer.log('Failed to spawn stdout isolate: $error', name: 'Stockfish');
    return false;
  }

  try {
    print("8");
    await Isolate.spawn(_isolateMain, [bindings, mainAndStdout[1] as SendPort]);
  } catch (error) {
    developer.log('Failed to spawn main isolate: $error', name: 'Stockfish');
    return false;
  }

  return true;
}
