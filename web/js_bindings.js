const nnue_name = "nn-5af11540bbfe.nnue";

let s_read, s_write, s_main, s_init, s_state;

let ready = false;
let ready_cb = null;

Module.onRuntimeInitialized = async function () {
    let data = await fetch("assets/packages/flutter_stockfish_plugin/web/stockfish_data.bin");
    let b = new Uint8Array(await data.arrayBuffer());
    FS.createDataFile("/", nnue_name, b, true, false, true);
    s_read = Module.cwrap("stockfish_stdout_read", "char*", ["bool"], { async: false });
    s_write = Module.cwrap("stockfish_stdin_write", "ssize_t", ["char*"], { async: false });
    s_main = Module.cwrap("stockfish_start_main", "void", [], { async: false });
    s_init = Module.cwrap("stockfish_init", "int", [], { async: false });
    s_state = Module.cwrap("stockfish_last_main_state", "int", [], { async: false });
    ready = true;
    if (ready_cb) ready_cb();

}

function wait_ready(res) {
    if (ready) return void res();
    ready_cb = res;
}

let _listener_id = -1;
let _listener_line_cb = (_) => { };
let _listener_state_cb = (_) => { };
let _last_state = -2;
function _stockfish_listener() {
    let state = s_state();
    if(state >= 0 && _last_state != state){
        _listener_state_cb(state);
    }
    _last_state = state;
    let out = readline();
    while (out.length != 0) {
        _listener_line_cb(out);
        out = readline();
    }
    _listener_id = setTimeout(_stockfish_listener, 10);
}

function start_listening(line_cb = (_) => { }, state_cb = (_) => { }) {
    requestAnimationFrame(_stockfish_listener);
    _listener_line_cb = line_cb;
    _listener_state_cb = state_cb;
    s_init();
    s_main();
}

function stop_listening() {
    if (_listener_id != -1) clearTimeout(_listener_id);
    _listener_id = -1;
}

function _read() {
    let ptr = s_read(true);
    if (ptr == 0) {
        return -1;
    }
    return UTF8ToString(ptr);
}
var read_buffer = "";
function readline() {
    if (!read_buffer.includes("\n"))
        while (true) {
            let next = _read();
            if (next === -1) break;
            read_buffer += next;
            if (next.includes("\n")) break;
        }

    let index = read_buffer.indexOf("\n");
    let out = "";
    if (index == -1) {
        out = read_buffer;
        read_buffer = "";
    } else {
        out = read_buffer.substring(0, index);
        read_buffer = read_buffer.substring(index + 1);
    }
    return out;
}

function write(string) {
    let buffer = _malloc(string.length + 1);
    stringToUTF8(string, buffer, string.length + 1);
    let out = s_write(buffer);
    _free(buffer);
    return out;
}