#!/usr/bin/env bash
set -euo pipefail
mkdir -p artifacts
cargo bench --bench baseline | tee artifacts/baseline_run.txt
echo "Сравните artifacts/baseline_before.txt и artifacts/baseline_after.txt"