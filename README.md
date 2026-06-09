# PolyState

✨ **PolyState** is a lightning-fast, multithread-safe state management framework built in **Zig**, tailored for seamless integration via a robust **C-ABI**. It safely and dynamically manages heavily concurrency-bound states locally with no overhead.

![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)
![Language: Zig](https://img.shields.io/badge/Language-Zig-orange.svg)

## 🎯 Features
- 🚀 **Blazing Fast**: Engineered in Zig to squeeze every nanosecond of performance out of memory-bound state requests (~1.25M+ ops/sec native cycle).
- 🧵 **Thread-Safe by Design**: Handles massive concurrent tasks across threads asynchronously via lock-free state allocation logic.
- 🌉 **C Architecture Compatibility**: Exported tightly over standard C bindings. Fully static and shared bindings are rendered identically to the host native layout.
- 🛡️ **Guarded Operations**: Strict bounds & error testing handles out-of-bounds inputs, unallocated interactions, or duplicated states safely.

---

## 🚀 Getting Started

### Prerequisites
Make sure you have [Zig `0.15.2`](https://ziglang.org/download/) installed in your operating system path.

### Build the SDK
The build script automatically iterates your native target (or explicit target) and ships optimized, static/shared objects directly into localized `weon-sdk` artifacts.

```sh
# Will statically resolve dependencies and output the lib in /zig-out
zig build
```

To create standard `tar.gz` compressed releases for Linux, Windows and Apple:
```sh
zig build archive
```

### Running Tests
The project rigorously validates its claims through automated testing covering thread-collisions, raw C imports, limit validations, and bounds security.

```sh
zig build test
```

## 💻 Integration (C/C++)
To utilize PolyState within your native C / C++ environments, simply include the bindings shipped in `include` and link your program to `weon-sdk` created by the build step.

```c
#include <stdio.h>
#include <poly_state/api.h>

int main() {
    poly_state_init();
    
    uint64_t id = 42;
    PolyState.create(id, 512);

    BUFFER_WRITE writer;
    PolyState.write(id, &writer);
    sprintf((char*)writer.data, "Hello PolyState!");

    BUFFER_READ reader;
    PolyState.read(id, &reader);
    printf("State Output: %s\n", (const char*)reader.data);

    PolyState.erase(id);
    return 0;
}
```

## 🔒 License Limitations
This software is officially provided under the **GNU General Public License v3.0 (GPL-3.0)**. 
As a strict copyleft license, it legally requires any derivative projects, modifications, or implementations that integrate **PolyState** to be completely open-sourced under the same, compatible strict rights. This framework **cannot** be legally baked into closed-source proprietary stacks. See the [LICENSE](./LICENSE) file for further legal information.
