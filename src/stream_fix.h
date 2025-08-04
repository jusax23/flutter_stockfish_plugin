#ifndef _STREAM_FIX_H_
#define _STREAM_FIX_H_
#include <condition_variable>
#include <iostream>
#include <mutex>
#include <queue>
#include <sstream>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#include <emscripten/threading.h>
#endif

template <typename T>
inline std::string stringify(const T& input) {
    std::ostringstream output;
    output << input;
    return std::string(output.str());
}

class FakeStream {
  public:
    template <typename T>
    FakeStream& operator<<(const T& val) {
        if (closed)
            return *this;
        std::lock_guard<std::mutex> lock(mutex_guard);
        string_queue.push(stringify(val));
        mutex_signal.notify_one();
        return *this;
    }

    template <typename T>
    FakeStream& operator>>(T& val) {
        if (closed)
            return *this;
        std::unique_lock<std::mutex> lock(mutex_guard);
#ifdef __EMSCRIPTEN__
        if (emscripten_is_main_runtime_thread()) {
            lock.unlock();
            while (true) {
                lock = std::unique_lock<std::mutex>(mutex_guard);
                if (!string_queue.empty() || closed)
                    break;
                lock.unlock();
                emscripten_sleep(10);
            }
        } else {
            mutex_signal.wait(
                lock, [this] { return !string_queue.empty() || closed; });
        }
#else
        mutex_signal.wait(lock,
                          [this] { return !string_queue.empty() || closed; });
#endif
        if (closed)
            return *this;
        val = string_queue.front();
        string_queue.pop();
        return *this;
    }

    bool try_get_line(std::string&);

    void open();
    void close();
    bool is_closed();

    std::streambuf* rdbuf();
    std::streambuf* rdbuf(std::streambuf*);

  private:
    bool closed = false;
    std::queue<std::string> string_queue;
    std::mutex mutex_guard;
    std::condition_variable mutex_signal;
};

namespace std {
bool getline(FakeStream& is, std::string& str);
} // namespace std

extern FakeStream fakeout;
extern FakeStream fakein;
extern std::string fakeendl;

#endif
