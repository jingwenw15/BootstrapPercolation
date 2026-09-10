# Candidate Conjectures

This file records conjectures suggested by the exact computations. They are not
proved.

## Conjecture 1: Exact Formula For 2 x n

For every `n >= 2`,

```text
E(2,n) = floor(2(n + 2) / 3).
```

Equivalently, the Morris upper bound is sharp for every `2 x n` rectangle.

Evidence:

- verified exactly for `2 <= n <= 12`;
- every tested `2 x n` case attains the upper-bound start immediately;
- this is the simplest family where a direct proof may be possible.

## Conjecture 2: Small-Rectangle Gap Is At Most One

For the computed range,

```text
E(m,n) >= floor((m + 2)(n + 2) / 6) - 1.
```

Equivalently, every tested rectangle either attains Morris's upper bound or
falls exactly one below it.

Evidence:

- verified for all `2 <= m <= n <= 5`;
- additionally verified for `2 x 6`, `3 x 6`, `4 x 6`;
- extended thin-family checks through `2 x 12`, `3 x 9`, and `4 x 7`.

This conjecture is much more speculative than the `2 x n` formula.

## Conjecture 3: Exact Formula For 4 x n

For at least the initial values `4 <= n <= 7`, the exact value is

```text
E(4,n) = n + 1.
```

This is one below Morris's upper-bound start, since

```text
floor((4 + 2)(n + 2) / 6) = n + 2.
```

Evidence:

| n | E(4,n) |
|---|-------:|
| 4 | 5 |
| 5 | 6 |
| 6 | 7 |
| 7 | 8 |

The `4 x 7` case is particularly rigid, with only two raw maximizers.

## Most Promising Proof Target

The `2 x n` formula is the best first target. A proof would likely need:

1. an explicit construction reaching `floor(2(n + 2) / 3)`;
2. an upper-bound argument showing that a larger inclusion-minimal percolating
   set cannot exist on two rows.

Because a `2 x n` grid has only vertical pairs and horizontal chains, it should
be possible to translate the process into a one-dimensional constraint problem
on columns.
