# Exact Counting of Height-Four Maximizers

## Result

Let `C(n)` count all distinct seed sets of size `E(4,n)` that are minimal
percolating on the labeled `4 x n` grid. Reflections and rotations are not
identified. The new calculation counts all maximizers, not just the repeating
construction in the manuscript.

There are certified, constant-coefficient recurrences for each sequence:

| Sequence a(k), k >= 0 | Recurrence order | Exponent j below |
|---|---:|---:|
| `C(19+3k)` | 30 | 2 |
| `C(20+3k)` | 58 | 4 |
| `C(21+3k)` | 44 | 3 |

All three recurrence polynomials have the form

```text
(t - 2)^2 Q(t)^j,
```

where the descending coefficients of the same monic degree-14 polynomial
`Q` are

```text
[1, -58, 1476, -21984, 215261, -1473558, 7310294, -26830952,
 73529728, -150262400, 226017568, -243082624, 176835200,
 -77831424, 15593472].
```

The coefficients and enough starting counts to determine all later terms are
stored as exact decimal integers in
`experiments/results/width4_count_recurrences.toml`. Specifically, for a record
with order `d` and coefficient list `c`, the convention is

```text
a(k+d) = c[1] a(k+d-1) + ... + c[d] a(k), for every k >= 0.
```

For example, the first terms are:

| n | C(n) |
|---:|---:|
| 19 | 712,480 |
| 20 | 833,469,300 |
| 21 | 157,705,208 |
| 22 | 11,891,776 |
| 23 | 14,160,411,696 |
| 24 | 2,602,006,576 |

These particular finite counts were already present in our earlier packed
frontier computation. The progress here is an exact, independently derived
counting representation and a proof that the recurrences hold for all later
widths, rather than numerical extrapolation from that table. We do not claim
that these are the lowest-order possible recurrences, an asymptotic growth
constant, a geometric classification, or a literature-confirmed novel result.

## Why the Optimal Language Is Complete

The independently audited semantic graph has deterministic seed-column labels.
After the three-column warm-up, let `v_n(s)` be the largest seed count of any
prefix ending at state `s`, restricted to states that can reach a valid right
boundary. Its verified full-vector recurrence is

```text
v_(n+3) = v_n + 2, n >= 19.
```

An accepted maximizing word must attain `v_n(s)` at every prefix state. If not,
replace its prefix with a larger prefix of the same length and state. The same
suffix still accepts, producing a larger minimal percolating set, a
contradiction. Conversely, a path that follows score-attaining edges and ends
at an accepting state with the global best score is a maximizing word.

Use phases corresponding to widths 19, 20, and 21 modulo three. Retain exactly
the edges that attain the next phase's score, adding two at a phase wrap.
Mark as accepting only the phase/state pairs with a globally optimal accepted
score. Trim states unreachable from optimal width-19 prefixes or unable to
reach any marked accepting state. This gives 14,651 states and 37,032 labeled
edges. The initial weight of each state is the exact number of best width-19
prefixes ending there, recomputed by the independent semantic implementation.

Every word has a unique path. Distinct column labels are counted separately,
even when their endpoints coincide. Initial counts use arbitrary-precision
integers. Consequently, ordinary path counting on this graph gives exactly
`C(n)` for every `n >= 19`.

## Exact Counting Quotient

Partition states first by their accepting flag, then repeatedly refine by the
multiset of outgoing destination blocks. The previous block is part of each
refinement signature, so blocks can split but never merge. At termination,
every state in a block has the same accepting flag and the same number of
outgoing labeled edges to every other block.

Sum the starting counts within each block and retain these edge multiplicities.
Induction on path length shows the quotient preserves total accepted path
counts exactly. The resulting representation has 847 states and 2,434
weighted edges. This is a counting quotient, not a label-preserving automaton
for enumerating the actual grid words.

## Why the Recurrence Check Proves All Widths

Let `M` be the quotient's integer transition matrix, `b` its initial count
vector, and `c` its accepting indicator. For offset `r` in `{0,1,2}`,

```text
a(k) = c^T (M^3)^k M^r b = C(19+r+3k).
```

Modular Berlekamp-Massey and Chinese remaindering propose integer recurrence
coefficients. This is only discovery: it does not prove anything by itself.

For each proposed polynomial `P`, the exact checker calculates the first 847
residuals

```text
R(k) = c^T (M^3)^k P(M^3) M^r b, k = 0,...,846.
```

All are zero using arbitrary-precision integer arithmetic. Cayley-Hamilton
for the 847-dimensional matrix `M^3` implies that `R` itself satisfies a monic
order-847 recurrence. These initial zeros force every later residual to be
zero. Thus the proposed recurrence is valid for every `k >= 0`. Exact
polynomial multiplication separately checks the displayed common-factor
identity. No floating-point arithmetic or assumed stabilization is used.

The guarantee inherits the audited semantic graph and ordinary Julia runtime;
it is a computer-assisted proof, not a Lean formalization or external review.

## Reproduction and Tests

```text
julia --project=. experiments/certify_width4_counts.jl
julia --project=. experiments/width4_optimal_language.jl 80
julia --project=. test/runtests.jl
```

The first command performs the complete semantic audit, rebuilds the counting
quotient, discovers and exactly certifies all three recurrences, checks their
factorization, and regenerates the TOML artifact. The second performs the same
semantic audit and prints counts from the quotient through the chosen width.

The tests check every quotient-state identity, compare the full and quotient
counts through width 80, compare the older packed-frontier counts through
width 40, and independently exhaust all `4 x 3` and `4 x 4` grids using direct
bootstrap closure and every single-seed deletion. They verify all 847 exact
residuals for each stored recurrence and reject changed coefficients.

The attempted simpler shortcut also had a useful negative outcome: the state
used by our explicit `[1,1,0]` construction has no second two-seed, three-column
loop. Thus the large number of maximizers is not explained by independently
choosing between two such loops at that one state. A geometric explanation of
the common polynomial and its residue-dependent powers remains open in our
project.
