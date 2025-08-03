# flutter_stockfish_plugin

A Flutter plugin for the Stockfish Chess engine.

The current version is based on Stockfish 17.

## Usage

```dart
final stockfish = new Stockfish()

// Listen on stdout of Stockfish engine
final stockfishSubscription = stockfish.stdout.listen((line) {
    print("received: $line");
});

// Sending UCI command to get Stockfish ready
stockfish.stdin = 'isready'

stockfish.stdin = 'position startpos moves e2e4' // set up start position
stockfish.stdin = 'go depth 20' // search bestmove with a max septh of 20

// Don't remember to dispose Stockfish when you're done.
// Make shure to dispose Stockfish when closing the app. May use WindowListener.
stockfishSubscription.cancel();
stockfish.dispose();
```

A complete Example can be found at [stockfish_chess_engine](https://github.com/loloof64/StockfishChessEngineFlutter).

## Web support
Web support is currently experimental and requires manually adding assets. It uses a version of stockfish compiled with [emscripten](https://emscripten.org/).

Usage:
- Install `emscripten` and set the the Environment-Variable `EMSDK`
- Build the CMakeLists.txt in `web/`
- Copy the following files to `web/stockfish/` in your project: 
  - flutter_stockfish_plugin.js
  - flutter_stockfish_plugin.wasm
  - js_bindings.js
  - stockfish_data_small.bin
  - stockfish_data_big.bin

If a different path should be used: Change the path const's in `js_bindungs.js` and `stockfish_web_bindings.dart`

In order to make multithreading available, the site must run in a secure environment. 
The following headers must be set for this:

- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`

Problems:
- The current version does not include the `.js`, `.wasm` and neural network data as assets. 
This files will not be bundles automatically on the web.


## Goal of this fork of stockfish_chess_engine

* Avoid limitation. This version does not redirect stdout and stdin of the app for communication with stockfish.
* stdin and stdout were replaced with a fakestream element.
* Stockfish internal logging might not work (could be fixed).

## Credits
* Based on and using source code from [stockfish_chess_engine](https://github.com/loloof64/StockfishChessEngineFlutter)
* Using source code from [Stockfish](https://stockfishchess.org).
* Using source code from [Flutter Stockfish](https://github.com/ArjanAswal/Stockfish).

Directory src/Stockfish contains the latest current release.
The code is modified to use a different communication interface.
The original license for [Stockfish](https://stockfishchess.org) can be found in their [GitHub](https://github.com/official-stockfish/Stockfish) repository.

Directory web/ may contains code compiled from [emscripten](https://emscripten.org/). Emscripten is licensed among others under the MIT License. [License Page](https://emscripten.org/docs/introducing_emscripten/emscripten_license.html)