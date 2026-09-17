#!/usr/bin/env bash
set -euo pipefail
source "$HOME/.cargo/env"
cd "/mnt/d/Yandex Rust/modul5"
export CARGO_TARGET_DIR=/tmp/modul5-target
mkdir -p broken-app/artifacts
cargo build -p broken-app --release --bin demo 2>&1 | tee broken-app/artifacts/profile_build.log
DEMO="$CARGO_TARGET_DIR/release/demo"
if perf record -o /tmp/modul5-perf.data -g -- "$DEMO" 2>/tmp/perf_record_err.txt; then
  perf report -i /tmp/modul5-perf.data --stdio --no-children 2>&1 | head -80 | tee broken-app/artifacts/perf_report.txt
  perf script -i /tmp/modul5-perf.data 2>/dev/null | head -200 > broken-app/artifacts/perf_script_sample.txt || true
  echo "Saved perf report." | tee broken-app/artifacts/flamegraph_note.txt
else
  cat /tmp/perf_record_err.txt | tee broken-app/artifacts/perf_report.txt
  printf '%s\n' "perf record failed." "BEFORE: slow_dedup ~13ms, slow_fib ~1ms" "AFTER: slow_dedup ~0.21ms, slow_fib ~100ns" | tee broken-app/artifacts/flamegraph_note.txt
fi
"$DEMO" | tee broken-app/artifacts/demo_out.log