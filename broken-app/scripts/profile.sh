#!/usr/bin/env bash
set -euo pipefail
# См. также ../../scripts/run_profile.sh (WSL)
cargo build --release --bin demo
perf record -g ./target/release/demo || true
perf report || true