pub mod algo;
pub mod concurrency;

/// Сумма чётных значений (безопасный проход по срезу).
pub fn sum_even(values: &[i64]) -> i64 {
    values.iter().copied().filter(|v| v % 2 == 0).sum()
}

/// Подсчёт ненулевых байтов без утечек и лишних аллокаций.
pub fn leak_buffer(input: &[u8]) -> usize {
    input.iter().filter(|b| **b != 0).count()
}

/// Нормализация: убираем все виды пробельных символов и приводим к нижнему регистру.
pub fn normalize(input: &str) -> String {
    input
        .split_whitespace()
        .collect::<String>()
        .to_lowercase()
}

/// Усреднение только положительных чисел.
pub fn average_positive(values: &[i64]) -> f64 {
    let mut sum = 0_i64;
    let mut count = 0_usize;
    for &v in values {
        if v > 0 {
            sum += v;
            count += 1;
        }
    }
    if count == 0 {
        return 0.0;
    }
    sum as f64 / count as f64
}

/// Ранее содержала use-after-free; теперь безопасна и возвращает 84 (42 + 42).
pub fn use_after_free() -> i32 {
    let b = Box::new(42_i32);
    let val = *b;
    val + val
}
