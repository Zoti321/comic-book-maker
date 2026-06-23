# unrar-ng-sys 0.7.7 patch

Upstream crate: https://crates.io/crates/unrar-ng-sys/0.7.7

## Why patched

`build.rs` used `cfg!(windows)` and `#[cfg(windows)]`, which refer to the **build host**, not the compilation target. Cross-compiling from Windows to Android incorrectly compiled Windows-only sources (`isnt.cpp`, `motw.cpp`) with the NDK toolchain, causing the Cargokit / Flutter Android build to fail and leaving `libcomic_book_maker_core.so` missing at runtime.

## Change

Gate Windows-only UnRAR sources and link flags on `CARGO_CFG_TARGET_OS == "windows"` instead of host `cfg!(windows)`.

On Android, define `UNIX_TIME_NS` so symlink timestamp updates use `utimensat` instead of `lutimes` (not exposed in bionic without `_BSD_SOURCE`).

Only emit `-lpthread` for Linux desktop targets; Android bionic provides pthread via libc and `-lpthread` breaks cdylib linking.

On Android, emit `cargo:rustc-link-lib=c++_shared` so the FRB cdylib links NDK libc++ for embedded UnRAR C++ objects. Pair with `libc++_shared.so` copied in cargokit `build_gradle.dart`.

On macOS/iOS, Cargokit force-loads `libcomic_book_maker_core.a` from Xcode; `comic_book_maker_core.podspec` adds `-lc++` so UnRAR C++ symbols resolve at app link time. `build.rs` also emits `cargo:rustc-link-lib=c++` for Apple targets.

Remove this vendored copy once upstream merges an equivalent fix.
