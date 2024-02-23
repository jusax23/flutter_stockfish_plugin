import 'dart:async';

abstract class StockfishChessEngineAbstractBindings {
  final stdoutController = StreamController<String>.broadcast();
  Future<int> stockfishMain(Function active);
  void cleanUp(int exitCode);
  void write(String line);
  Stream<String> get read => stdoutController.stream;
}
