import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';
import 'package:flutter_stockfish_plugin/stockfish_c_bindings_generated.dart';

const String _libName = 'flutter_stockfish_plugin';

/// The dynamic library in which the symbols for [StockfishChessEngineCBindings] can be found.
final DynamicLibrary _dylib = () {
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

/// The bindings to the native functions in [_dylib].
final StockfishChessEngineCBindings _bindings =
    StockfishChessEngineCBindings(_dylib);

class StockfishChessEngineBindings
    extends StockfishChessEngineAbstractBindings {
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();
  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;

  @override
  Future<int> stockfishMain(Function active) {
    final completer = Completer<int>();
    _mainSubscription = _mainPort.listen((message) {
      cleanUp(message is int ? message : 1);
      completer.complete(message is int ? message : 1);
    });
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        stdoutController.sink.add(message);
      } else {
        developer.log('The stdout isolate sent $message', name: 'Stockfish');
      }
    });
    compute(_spawnIsolates, [_mainPort.sendPort, _stdoutPort.sendPort]).then(
      (success) {
        if (success) {
          active();
        } else {
          completer.completeError('Unable to create Isolates');
          cleanUp(1);
        }
      },
      onError: (error) {
        developer.log('The init isolate encountered an error $error',
            name: 'Stockfish');
        cleanUp(1);
      },
    );
    return completer.future;
  }

  @override
  void write(String line) {
    final unicodePointer = '$line\n'.toNativeUtf8();
    final pointer = unicodePointer.cast<Char>();
    _bindings.stockfish_stdin_write(pointer);
    calloc.free(unicodePointer);
  }

  @override
  void cleanUp(int exitCode) {
    stdoutController.close();
    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = _bindings.stockfish_main();
  mainPort.send(exitCode);

  developer.log('nativeMain returns $exitCode', name: 'Stockfish');
}

void _isolateStdout(SendPort stdoutPort) {
  String previous = '';

  while (true) {
    final pointer = _bindings.stockfish_stdout_read(0);

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

Future<bool> _spawnIsolates(List<SendPort> mainAndStdout) async {
  final initResult = _bindings.stockfish_init();
  if (initResult != 0) {
    developer.log('initResult=$initResult', name: 'Stockfish');
    return false;
  }

  try {
    await Isolate.spawn(_isolateStdout, mainAndStdout[1]);
  } catch (error) {
    developer.log('Failed to spawn stdout isolate: $error', name: 'Stockfish');
    return false;
  }

  try {
    await Isolate.spawn(_isolateMain, mainAndStdout[0]);
  } catch (error) {
    developer.log('Failed to spawn main isolate: $error', name: 'Stockfish');
    return false;
  }

  return true;
}
