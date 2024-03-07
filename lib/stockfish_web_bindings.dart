// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js' as js;
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter_stockfish_plugin/stockfish_bindings.dart';

const jsPath = "stockfish/";

class StockfishChessEngineBindings
    extends StockfishChessEngineAbstractBindings {
  Future<void>? loadJs;
  StockfishChessEngineBindings() {
    loadJs = loadJsFileIfNeeded();
  }

  @override
  void cleanUp(int exitCode) {
    stdoutController.close();
    js.context.callMethod("stop_listening", []);
  }

  @override
  Future<int> stockfishMain(Function active) async {
    if (loadJs != null) {
      await loadJs;
      loadJs = null;
    }
    final completer = Completer<int>();
    js.context.callMethod("start_listening", [
      (line) => stdoutController.sink.add(line),
      (state) {
        cleanUp(state is int ? state : 1);
        completer.complete(state is int ? state : 1);
      }
    ]);
    active();
    return completer.future;
  }

  @override
  void write(String line) {
    js.context.callMethod("write", [line]);
  }
}

bool _jsloaded = false;

Future<void> loadJsFileIfNeeded() async {
  if (kIsWeb && !_jsloaded) {
    final stockfishScript = html.document.createElement("script");
    stockfishScript.setAttribute("src", "${jsPath}flutter_stockfish_plugin.js");
    html.document.head?.append(stockfishScript);

    await stockfishScript.onLoad.first;

    final jsBindingsScript = html.document.createElement("script");
    jsBindingsScript.setAttribute("src", "${jsPath}js_bindings.js");
    html.document.head?.append(jsBindingsScript);

    await jsBindingsScript.onLoad.first;

    _jsloaded = true;
  }
  await _stockfishWaitReady();
}

Future<dynamic> _stockfishWaitReady() {
  final completer = Completer<dynamic>();
  js.context.callMethod('wait_ready', [
    completer.complete,
  ]);
  return completer.future;
}
