# flutter_stockfish_plugin

A Flutter plugin for the Stockfish Chess engine.

The current version is based on Stockfish 16.

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
Web support is currently experimental and currently requires manuly adding assets. It uses a version of stockfish compiled with [emscripten](https://emscripten.org/).

In order to make multithreading available, the site must run in a secure environment. 
The following headers must be set for this:

- `Cross-Origin-Embedder-Policy: require-corp`
- `Cross-Origin-Opener-Policy: same-origin`

Problems:
- The current version includes the `.js`, `.wasm` and neuralnetwork data as assets. 
These files are bundled with every build on every platform, even if they are not needed. 
This approach wasts about 41MB, if not striped out by hand.


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