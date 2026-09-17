#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.cargo/env"
cd "/mnt/d/Yandex Rust/modul5"
export CARGO_TARGET_DIR=/tmp/modul5-target
mkdir -p broken-app/artifacts

echo "=== cargo test ==="
cargo test -p broken-app 2>&1 | tee broken-app/artifacts/cargo_test_wsl.log

echo "=== miri ==="
rustup +nightly component add miri rust-src >/dev/null || true
cargo +nightly miri test -p broken-app --test integration 2>&1 | tee broken-app/artifacts/miri_test.log

echo "=== valgrind ==="
cargo test -p broken-app --test integration --no-run 2>&1 | tee broken-app/artifacts/valgrind_build.log
BIN=$(find "$CARGO_TARGET_DIR/debug/deps" -name 'integration-*' -type f -executable ! -name '*.d' | head -1)
echo "BIN=$BIN"
valgrind --leak-check=full --show-leak-kinds=all --error-exitcode=0 "$BIN" 2>&1 | tee broken-app/artifacts/valgrind.log

echo "=== asan ==="
rustup +nightly target add x86_64-unknown-linux-gnu >/dev/null || true
set +e
RUSTFLAGS="-Zsanitizer=address" cargo +nightly test -p broken-app --test integration --target x86_64-unknown-linux-gnu -Zbuild-std 2>&1 | tee broken-app/artifacts/asan.log
ASAN_RC=$?
if [ $ASAN_RC -ne 0 ]; then
  echo "ASan build-std failed; retry without build-std" | tee -a broken-app/artifacts/asan.log
  RUSTFLAGS="-Zsanitizer=address" cargo +nightly test -p broken-app --test integration --target x86_64-unknown-linux-gnu 2>&1 | tee -a broken-app/artifacts/asan.log
fi
set -e

echo "=== tsan ==="
set +e
RUSTFLAGS="-Zsanitizer=thread" cargo +nightly test -p broken-app --test integration --target x86_64-unknown-linux-gnu -Zbuild-std 2>&1 | tee broken-app/artifacts/tsan.log
TSAN_RC=$?
if [ $TSAN_RC -ne 0 ]; then
  echo "TSan build-std failed; retry without build-std" | tee -a broken-app/artifacts/tsan.log
  RUSTFLAGS="-Zsanitizer=thread" cargo +nightly test -p broken-app --test integration race_increment --target x86_64-unknown-linux-gnu 2>&1 | tee -a broken-app/artifacts/tsan.log
fi
set -e

echo "=== DONE dynamic analysis ==="