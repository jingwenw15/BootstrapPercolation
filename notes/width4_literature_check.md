# Width-Four Literature Check

Checked on 2026-10-10.

## Question

Has the exact formula

```text
E(4,n) = floor((2n + 10) / 3), n >= 5,
```

already appeared for largest inclusion-minimal percolating sets in two-neighbor
bootstrap percolation on the `4 x n` grid?

## Sources Found

Robert Morris introduced the parameter `E(m,n)` for this problem in
"Minimal Percolating Sets in Bootstrap Percolation," Electronic Journal of
Combinatorics 16 (2009), #R2:

https://doi.org/10.37236/91

Morris proves exact formulas when one dimension is 1, 2, or 3, a general upper
bound, and asymptotic square-grid results. The paper does not state an exact
formula for width 4.

Marinus Gottschau's 2020 dissertation, "Cuts, Paths, and Processes in Graphs,"
contains the closest prior result found:

https://d-nb.info/1220423823

Its Lemma 55 proves

```text
E(4,m) <= (4/5)m + 12/5.
```

The accompanying table gives exact values through `m = 11`, and the text
explicitly notes `E(4,11) = 10`. Consequently, our values through 11 are
independent confirmations, not novel values. The dissertation does not state
an all-`m` width-four formula or the period-three recurrence found here.

Denis Bashkirov's 2024 preprint, "Percolating Sets and the Operad of
Permutations," studies percolating permutation matrices and cites Morris's
extremal result:

https://arxiv.org/abs/2411.00753

It does not address the maximum size `E(4,n)` for width-four rectangles.

Later papers located through searches for largest minimal percolating sets
primarily concern hypercubes, trees, minimum percolating sets, or percolation
time. None of the searched sources stated the formula above.

## Search Terms

Searches included exact and variant forms of:

```text
"E(4,n)" bootstrap percolation
"E(4,m)" minimal percolating
"4 x n" largest minimal percolating set
"floor((2n+10)/3)" percolating
papers citing "Minimal percolating sets in bootstrap percolation"
```

## Assessment

The exact all-`n` formula and its finite-state recurrence certificate are
plausibly new. This search does not establish novelty. Before publication, the
claim should be checked through MathSciNet, zbMATH, Google Scholar citation
chains, and direct contact with researchers familiar with Morris's problem and
Gottschau's dissertation.

The defensible current wording is:

```text
We found no prior exact formula for E(4,n). The closest source found gives a
weaker all-n upper bound and exact values only through n=11.
```
