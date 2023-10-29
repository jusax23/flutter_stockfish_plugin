curl -s https://api.github.com/repos/official-stockfish/Stockfish/releases/latest \
| grep "tarball_url" \
| cut -d : -f 2,3 \
| tr -d "\", " \
| wget -qi - -O Stockfish.tar.gz
rm -rf Stockfish
mkdir -p Stockfish
tar -xzf Stockfish.tar.gz --directory Stockfish --strip-components=1
rm Stockfish.tar.gz
find ./Stockfish/ -type f -exec sed -i \
    -e 's/std::cout/fakeout/g' \
    -e 's/std::cin/fakein/g' \
    -e 's/std::endl/fakeendl/g' \
    -e 's/getline(cin, cmd)/getline(fakein, cmd)/g' \
    {} +

nnue_name=$(grep EvalFileDefaultName Stockfish/src/evaluate.h \
| grep define \
| sed 's/.*\(nn-[a-z0-9]\{12\}.nnue\).*/\1/')

sed -i "s/set(NNUE_NAME nn-[^)]*.nnue)/set(NNUE_NAME $nnue_name)/" CMakeLists.txt