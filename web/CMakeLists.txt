# The Flutter tooling requires that developers have CMake 3.18 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.18)

project(flutter_stockfish_plugin)
file(GLOB_RECURSE cppPaths "../src/Stockfish/src/*.cpp")
set(CMAKE_CXX_STANDARD 17)

set(NNUE_NAME_SMALL nn-37f18f62d772.nnue)
set(NNUE_NAME_BIG nn-1c0000000000.nnue)

add_definitions(-DNNUE_EMBEDDING_OFF) # embeding nnue network is currently not supported.

set(EMSCRIPTEN_PATH "$ENV{EMSDK}/upstream/emscripten" CACHE STRING "Path to Emscripten")
set(CMAKE_TOOLCHAIN_FILE "${EMSCRIPTEN_PATH}/cmake/Modules/Platform/Emscripten.cmake" CACHE STRING "Emscripten toolchain file")
set(CMAKE_CXX_COMPILER "${EMSCRIPTEN_PATH}/em++")

set(COMMON_FLAGS "-Wall -Wcast-qual -Wno-main -fno-exceptions -std=c++17 -pedantic -Wextra -Wshadow -Wmissing-declarations -flto") 
set(SIMD_FLAGS "${CMAKE_CXX_FLAGS} -msimd128 -mavx -msse -DUSE_SSE2 -msse2 -msse3 -DUSE_SSSE3 -mssse3 -DUSE_SSE41 -msse4.1 -DUSE_SSE42 -msse4.2")

set(EM_FLAGS "${EM_FLAGS} -s WASM=1 -sASYNCIFY")
set(EM_FLAGS "${EM_FLAGS} -s EXPORTED_RUNTIME_METHODS=ccall,cwrap")
set(EM_FLAGS "${EM_FLAGS} -s TOTAL_STACK=8MB -s INITIAL_MEMORY=512MB -s ALLOW_MEMORY_GROWTH")
set(EM_FLAGS "${EM_FLAGS} -s PTHREAD_POOL_SIZE=32")


set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${SIMD_FLAGS} -O3 -DNDEBUG -s USE_PTHREADS=1 -Dmain=runMain")


add_executable(${PROJECT_NAME} 
  "../src/stockfish.cpp"
  "../src/stream_fix.cpp"
  "../src/small_fixes.cpp"
  ${cppPaths}
)

set_target_properties(${PROJECT_NAME} PROPERTIES LINK_FLAGS "${EM_FLAGS}")

set_target_properties(${PROJECT_NAME} PROPERTIES OUTPUT_NAME "${PROJECT_NAME}.js")

add_definitions(-include ../src/fixes.h)

target_include_directories(${PROJECT_NAME} 
  PUBLIC
  "./"
)


file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME_SMALL} ${CMAKE_BINARY_DIR}/stockfish_data_small.bin)
file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME_BIG} ${CMAKE_BINARY_DIR}/stockfish_data_big.bin)



