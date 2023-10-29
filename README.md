# flutter_stockfish_plugin

A Flutter plugin for Stockfish Chess engine.

The current Version is based on Stockfish 16.

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

## Goal of this fork of stockfish_chess_engine

* Avoid limitation. This Version does not redirect stdout and stdin of the app for communication with stockfish.
* stdin and stdout where replaced with a fakestream element.
* Stockfish internel Logging might not work (could be fixed).

## Credits
* Based on and using source code from [stockfish_chess_engine](https://github.com/loloof64/StockfishChessEngineFlutter)
* Using source code from [Stockfish](https://stockfishchess.org).
* Using source code from [Flutter Stockfish](https://github.com/ArjanAswal/Stockfish).

Directory src/Stockfish contains the latest current release.
The code is modified to use a different communication interface.
Original License of [Stockfish](https://stockfishchess.org) can be found in their [Github](https://github.com/official-stockfish/Stockfish) Repository.