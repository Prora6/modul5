# Модуль 5 — поиск ошибок и оптимизация

Workspace из двух крейтов:

- `broken-app` — исправленный и оптимизированный проект (сдаём его)
- `reference-app` — эталон поведения (исходники из официального zip без правок логики)

Исходники эталона: https://code.s3.yandex.net/middle-rust-blockchain/reference-app.zip  
SHA-256 ключевых файлов reference-app:

- `src/lib.rs` — `B627DB9C3EAB3CA440EA76C3A206CC200FF2977973EAD0F6D349E83C7F8B1B43`
- `src/algo.rs` — `852572D79182B9A564E403D985B1043056A5CB9E77E5EB6419983F290256848F`
- `src/concurrency.rs` — `27C4A46DEA7C42512FF71DEC6720758D00784A74A52EE783B08A5D00293DBEA2`

(В `Cargo.toml` эталона убрана зависимость `criterion`, чтобы `cargo build --workspace` работал без crates.io; логика кода не менялась.)

## Быстрый старт

```bash
cargo build --workspace
cargo test -p broken-app
cargo test -p reference-app
cargo bench -p broken-app --bench baseline
cargo run -p broken-app --bin demo
```

На Windows у двух пакетов одинаковое имя бинаря `demo` — при сборке workspace будет warning о коллизии; запускайте через `-p broken-app` / `-p reference-app`.

## Динамический анализ (Ubuntu WSL)

Требуется: `rustup` (stable+nightly), `miri`, `valgrind`, `perf`.

```bash
# из корня репозитория в WSL
bash scripts/run_dynamic_analysis.sh
bash scripts/run_profile.sh
```

Или вручную:

```bash
cargo test -p broken-app
cargo +nightly miri test -p broken-app --test integration
cargo test -p broken-app --test integration --no-run
valgrind --leak-check=full target/debug/deps/integration-*

# ASan / TSan (nightly + build-std)
RUSTFLAGS="-Zsanitizer=address" cargo +nightly test -p broken-app --test integration \
  --target x86_64-unknown-linux-gnu -Zbuild-std
RUSTFLAGS="-Zsanitizer=thread" cargo +nightly test -p broken-app --test integration \
  --target x86_64-unknown-linux-gnu -Zbuild-std
```

## Бенчмарки до / после

```bash
cargo bench -p broken-app --bench baseline
# результаты сохранены в broken-app/artifacts/baseline_before.txt и baseline_after.txt
```

Краткое сравнение: `broken-app/artifacts/bench_comparison.md`.

| Функция    | До      | После     | Ускорение |
|------------|---------|-----------|-----------|
| slow_dedup | ~13 ms  | ~0.21 ms  | ~62×      |
| slow_fib   | ~1 ms   | ~100 ns   | ~10⁴×     |

## Что было сломано и как починено

| Баг | Инструмент | Исправление |
|-----|------------|-------------|
| off-by-one / UB в `sum_even` | Miri, ASan, тесты | безопасный итератор |
| утечка в `leak_buffer` | Valgrind, Miri | без `Box::into_raw` |
| неверное среднее | тесты | только положительные |
| use-after-free | Miri, ASan | безопасная реализация |
| data race | TSan, Miri | `AtomicU64` |
| normalize без табов | регресс-тест | `split_whitespace` |
| медленный dedup/fib | bench, perf | HashSet + итеративный fib |

Подробности: `broken-app/artifacts/OPTIMIZATIONS.md`.

## Артефакты к сдаче

Каталог `broken-app/artifacts/`:

- `cargo_test_before.log` / `cargo_test.log` / `cargo_test_wsl.log`
- `miri_test.log`, `valgrind.log`, `asan.log`, `tsan.log`
- `baseline_before.txt`, `baseline_after.txt`, `bench_comparison.md`
- `flamegraph.svg`, `flamegraph_hotspots.txt`, `perf_report.txt`

## Чеклист перед отправкой

- [x] `cargo build --workspace` / `cargo test -p broken-app` — OK
- [x] Регрессионные тесты на найденные баги
- [x] `cargo +nightly miri test` — без UB
- [x] Valgrind — definitely lost: 0
- [x] ASan / TSan — без ошибок
- [x] Бенчмарки фиксируют ускорение
- [x] Оптимизации задокументированы