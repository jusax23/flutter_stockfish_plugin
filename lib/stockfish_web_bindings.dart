// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';

const jsPath = "stockfish/";

@JS("stop_listening")
external JSVoid stopListening();

@JS("start_listening")
external JSVoid startListening(
    JSExportedDartFunction onLine, JSExportedDartFunction onStateChange);

@JS("wait_ready")
external JSVoid waitReady(JSExportedDartFunction onComplete);

@JS("write")
external JSVoid fishWrite(JSString line);

/* // callbacks
@JS()
external set readyFunction(JSFunction value);
 */
class StockfishChessEngineBindings
    extends StockfishChessEngineAbstractBindings {
  Future<void>? loadJs;
  StockfishChessEngineBindings() {
    loadJs = loadJsFileIfNeeded();
  }

  @override
  void cleanUp(int exitCode) {
    stdoutController.close();
    stopListening();
  }

  @override
  Future<int> stockfishMain(Function active) async {
    if (loadJs != null) {
      await loadJs;
      loadJs = null;
    }
    final completer = Completer<int>();
    startListening(
        ((JSString line) => stdoutController.sink.add(line.toDart)).toJS,
        ((JSNumber state) {
          cleanUp(state.toDartInt);
          completer.complete(state.toDartInt);
        }).toJS);
    active();
    return completer.future;
  }

  @override
  void write(String line) {
    fishWrite(line.toJS);
  }
}

bool _jsloaded = false;

Future<void> loadJsFileIfNeeded() async {
  if (kIsWeb && !_jsloaded) {
    final stockfishScript = document.createElement("script");
    stockfishScript.setAttribute("src", "${jsPath}flutter_stockfish_plugin.js");
    document.head?.append(stockfishScript);

    await stockfishScript.onLoad.first;

    final jsBindingsScript = document.createElement("script");
    jsBindingsScript.setAttribute("src", "${jsPath}js_bindings.js");
    document.head?.append(jsBindingsScript);

    await jsBindingsScript.onLoad.first;

    _jsloaded = true;
  }
  await _stockfishWaitReady();
}

Future<dynamic> _stockfishWaitReady() {
  final completer = Completer<dynamic>();
  waitReady(() {
    completer.complete();
  }.toJS);
  return completer.future;
}
