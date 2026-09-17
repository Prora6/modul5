# Оптимизации и регрессионные тесты

## Исправленные дефекты

1. **sum_even** — off-by-one + `get_unchecked` → безопасный `filter`/`sum`.
2. **leak_buffer** — утечка `Box::into_raw` → подсчёт по срезу без аллокаций.
3. **average_positive** — среднее только по положительным (один проход, без Vec).
4. **use_after_free** — убран dangling-read; функция безопасна, возвращает 84.
5. **normalize** — `split_whitespace` + lowercase (табы/переводы строк).
6. **concurrency** — `static mut` → `AtomicU64` (SeqCst).

## Оптимизации (минимум две)

### Алгоритмическая: `slow_dedup`
Было: O(n²) линейный поиск + `sort_unstable` на каждой вставке.
Стало: `HashSet` + один `sort_unstable` в конце (~O(n log n)).
Ускорение на входе 5_000×2: **~13 ms → ~0.21 ms (~62×)**.

### Микро: `slow_fib` + аллокации
Было: экспоненциальная рекурсия.
Стало: итеративный цикл O(n).
Ускорение fib(28): **~1 ms → ~100 ns (~10⁴×)**.
Дополнительно: `leak_buffer`/`sum_even` без лишних alloc/copy.

## Регрессионные тесты (`tests/integration.rs`)

- `sums_even_numbers`, `sums_even_empty`
- `averages_only_positive`, `average_positive_empty_and_all_negative`
- `normalize_tabs_and_newlines`
- `race_increment_is_correct`
- `use_after_free_is_safe`
- `dedup_and_fib_sanity`

## Артефакты

См. `broken-app/artifacts/`: логи test/miri/valgrind/asan/tsan, baseline_before/after, flamegraph.