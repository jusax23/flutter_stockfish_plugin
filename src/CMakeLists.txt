# The Flutter tooling requires that developers have CMake 3.18 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.18)

project(flutter_stockfish_plugin VERSION 0.0.1 LANGUAGES CXX)
file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_FLAGS "-O3 -flto")
#set(CMAKE_CXX_FLAGS "-O3 -flto -march=native")
#old: -Wshadow -Wmissing-declarations -fno-exceptions -std=c++17 -fPIC -Wall -Wextra -march=native
#set(CMAKE_CXX_FLAGS_RELEASE "-O3 -flto -march=native")
set(NNUE_NAME nn-5af11540bbfe.nnue)

add_library(flutter_stockfish_plugin SHARED
  "stockfish.cpp"
  "stream_fix.cpp"
  ${cppPaths}
)

set_target_properties(flutter_stockfish_plugin PROPERTIES
  PUBLIC_HEADER stockfish.h
  OUTPUT_NAME "flutter_stockfish_plugin"
)

if(MSVC)
    add_definitions(/FI"stream_fix.h")
else()
    add_definitions(-include stream_fix.h)
endif()

target_compile_definitions(flutter_stockfish_plugin PUBLIC DART_SHARED_LIB)

target_include_directories(flutter_stockfish_plugin
  PUBLIC
  "./"
)


if (MSVC)
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME})
    file(COPY ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME} DESTINATION ${CMAKE_BINARY_DIR}/runner/Release)
else ()
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/${NNUE_NAME})
endif ()
