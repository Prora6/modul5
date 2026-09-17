use broken_app::{algo, concurrency, leak_buffer, normalize, sum_even, use_after_free};

#[test]
fn sums_even_numbers() {
    let nums = [1, 2, 3, 4];
    assert_eq!(sum_even(&nums), 6);
}

#[test]
fn sums_even_empty() {
    assert_eq!(sum_even(&[]), 0);
}

#[test]
fn counts_non_zero_bytes() {
    let data = [0_u8, 1, 0, 2, 3];
    assert_eq!(leak_buffer(&data), 3);
}

#[test]
fn dedup_preserves_uniques() {
    let uniq = algo::slow_dedup(&[5, 5, 1, 2, 2, 3]);
    assert_eq!(uniq, vec![1, 2, 3, 5]);
}

#[test]
fn fib_small_numbers() {
    assert_eq!(algo::slow_fib(10), 55);
}

#[test]
fn normalize_simple() {
    assert_eq!(normalize(" Hello World "), "helloworld");
}

#[test]
fn normalize_tabs_and_newlines() {
    assert_eq!(normalize("Hello\tWorld\nRust"), "helloworldrust");
}

#[test]
fn averages_only_positive() {
    let nums = [-5, 5, 15];
    assert!((broken_app::average_positive(&nums) - 10.0).abs() < f64::EPSILON);
}

#[test]
fn average_positive_empty_and_all_negative() {
    assert_eq!(broken_app::average_positive(&[]), 0.0);
    assert_eq!(broken_app::average_positive(&[-1, -2, 0]), 0.0);
}

#[test]
fn race_increment_is_correct() {
    let total = concurrency::race_increment(1_000, 4);
    assert_eq!(total, 4_000);
}

#[test]
fn use_after_free_is_safe() {
    assert_eq!(use_after_free(), 84);
}

#[test]
fn dedup_and_fib_sanity() {
    let uniq = algo::slow_dedup(&[9, 1, 9, 2, 1]);
    assert_eq!(uniq, vec![1, 2, 9]);
    assert_eq!(algo::slow_fib(15), 610);
}
