# Fixed-Width Eventual Growth: Stage 2

## Result and scope

For each fixed positive height `h`, there exist an effectively computable
positive integer `p` and integers `q_r, b_r, K_r`, for `0 <= r < p`, such that

```text
E(h, p*k + r) = q_r*k + b_r  whenever k >= K_r.
```

In particular the extremal size is eventually quasi-linear: on each residue
class it follows an exact straight line. Both the lower and upper limiting
densities are rational and effectively computable:

```text
liminf E(h,n)/n = min_r q_r/p,
limsup E(h,n)/n = max_r q_r/p.
```

This follows from the finite-state characterization in
`fixed_width_state_theorem.md` and the elementary argument below. Stage 3 in
`fixed_width_common_growth.md` now proves that all residue gains agree, using
Morris's published dimension-monotonicity lemma. Consequently the lower and
upper limiting densities above are equal and a common eventual recurrence
holds for every fixed `h`.

The mathematical tools concerning regular languages and semilinear sets are
classical. This note gives their proof and application here; it does not claim
these general tools as new mathematics or establish novelty of the resulting
bootstrap-percolation theorem.

## 1. The entire length-size spectrum is semilinear

Define

```text
S_h = {(n,s): there exists an inclusion-minimal percolating seed set of
                    size s on the h x n grid},   n >= 1.
```

A linear subset of the nonnegative integer plane has the form

```text
(a,b) + t_1*(l_1,w_1) + ... + t_m*(l_m,w_m),   t_i >= 0 integers.
```

A semilinear set is a finite union of linear sets. We show that `S_h` has
this form, effectively, with `l_i > 0` for all nonzero generators.

Stage 1 gives a finite deterministic automaton on seed-column patterns. To
make it literally finite-state, include a phase recording whether the prefix
has length zero, one, or at least two. All subsequent transitions use the same
interior rule. The right boundary is a fixed acceptance operation. A letter
`B` contributes the vector `(1, number of seeds in B)`.

**Lemma 1.** The additive vector image of any regular language is semilinear.

**Proof.** A finite automaton can be converted effectively into a regular
expression by eliminating states. Explicitly, if `R_ij^(k)` describes walks
from `i` to `j` whose intermediate states lie among the first `k` states, then

```text
R_ij^(k) = R_ij^(k-1) union
           R_ik^(k-1) (R_kk^(k-1))* R_kj^(k-1).
```

Start with single edges and empty walks, and take the union over initial and
accepting states at the final step. It suffices to check the three operations
in this expression after mapping concatenation to vector addition.

* A finite language has a finite vector image, a union of singleton linear
  sets. Union preserves semilinearity.
* The sum of two linear sets has base equal to the sum of their bases and
  generators equal to the union of their generators. Distributing over
  finite unions proves closure under concatenation.
* Let `S` be the union of `b_i + monoid(P_i)` for `1 <= i <= m`. The additive
  image of `S*` is `{0}` together with the following finite union, indexed by
  nonempty subsets `I` of `{1,...,m}`:

```text
sum_(i in I) b_i + monoid({b_i: i in I} union union_(i in I) P_i).
```

  Indeed, `I` records exactly which linear components supply at least one
  summand. Choose one base from each such component. Additional summands
  contribute more copies of its base, and all generator contributions may be
  attached to its first summand. Conversely every such expression is a sum of
  elements of `S`. This proves closure under star. QED.

Applying Lemma 1 to the seed-column automaton proves semilinearity of `S_h`.
Each component is a subset of `0 <= s <= h*n`. Consequently any generator of
zero length must also have zero weight; discard these zero vectors. All other
generators have positive length. A component with no generators is a singleton.

The conversion is effective but can be very large. We do not construct a
semilinear description of the height-four certificate graph in this stage.

## 2. The upper envelope of one linear family

Consider one infinite linear family with base `(a,b)` and generators
`(l_i,w_i)`, all `l_i > 0`. Choose a generator `(p,g)` of maximum ratio
`g/p = max_i w_i/l_i`. Define its nonnegative integer losses by

```text
d_i = g*l_i - p*w_i >= 0.
```

For a combination of generators of total length `L` and total weight `W`,
its loss is

```text
D = sum_i t_i*d_i = g*L - p*W.
```

For each reachable residue `r modulo p`, choose a combination minimizing
`D`, and among those choose one of minimum length `L_r`. Write its minimum
loss as `D_r`. Both minima exist by well-ordering of the nonnegative integers.

**Lemma 2.** Whenever `L >= L_r` and `L == r (mod p)`, the maximum achievable
weight of a generator combination of length `L` is exactly

```text
(g*L - D_r)/p.
```

**Proof.** Every combination at this residue has loss at least `D_r`, giving
the upper bound. Starting from the chosen witness at length `L_r`, append
`(L-L_r)/p` copies of `(p,g)`. Each has loss zero, so the resulting length-`L`
combination has loss exactly `D_r`, attaining the bound. QED.

Thus the family maximum at `n = a + L` is

```text
b + (g*(n-a) - D_r)/p.
```

Unreachable residues never occur in this family. To compute `D_r,L_r`, use a
graph on residues modulo `p`: a generator gives an edge of displacement `l_i`
and lexicographic cost `(d_i,l_i)`. Shortest paths from residue zero minimize
loss first and length second. The first coordinate is nonnegative and every
edge has positive second coordinate, so a shortest path can be taken simple.
This also supplies finite generator-multiplicity witnesses for every residue.

## 3. A finite union is eventually affine on each residue

Take a common period `P` divisible by the chosen `p` of every infinite linear
family. Restrict lengths to `n = P*k + r` for one fixed residue `r`.

By Lemma 2, each family is either absent on this residue, or for all sufficiently
large `k` its maximum is an integer affine function

```text
Q_i*k + B_i,    Q_i = P*g_i/p_i.
```

Singleton families disappear after their sole lengths. Among the remaining
finitely many affine functions, the one with largest slope eventually wins;
ties are resolved by largest intercept. Every crossover threshold is computable
using integer division. Taking the maximum over the families proves:

**Theorem 4.** For a finite weighted automaton with nonnegative integer edge
weights, on each residue modulo an effective common period its maximum accepted
path weight is eventually either absent or an integer affine function.

For integer edge weights of arbitrary sign, add a fixed nonnegative constant
`C` to each edge so all edge weights become nonnegative. At length `n` this
adds exactly `C*n` to every accepted path weight. Apply the theorem, then
subtract `C*n`. Thus the same conclusion holds for arbitrary integer weights.

Some residues may be eventually absent for a general automaton. They are
never absent for the bootstrap automaton: the fully infected finite grid
percolates, and repeatedly removing any removable seed terminates at an
inclusion-minimal percolating subset. This exists for every positive `h,n`.

**Corollary 5.** For every fixed positive height `h`, `E(h,n)` is eventually
quasi-linear as stated at the beginning of this note. Its residue slopes,
lower limiting density, and upper limiting density are rational and effectively
computable.

## 4. Why monotonicity is needed for a common growth rate

Consider a weighted automaton with two disjoint branches. One accepts only
even lengths `2k` with weight `2k`, and the other accepts only odd lengths
`2k+1` with weight zero. This is a finite automaton and it accepts every
nonnegative length, yet the maximum divided by length has no limit.

Its spectrum is the union of the two families

```text
(0,0) + k*(2,2),
(1,0) + k*(2,0).
```

Our general automaton theorem permits exactly this behavior. Either of the
following additional properties would force a single slope:

* `E(h,n)` is nondecreasing in `n`; or
* there is a constant `C_h` with `E(h,n+1) >= E(h,n)-C_h` for all large `n`.

Either condition, together with eventual residue-wise affinity, forces equal
slopes: if the gains are not all equal, cycling through adjacent residues
includes a strict decrease in gain. At that adjacent residue pair the drop
grows without bound as `k` increases, contradicting either condition. A
two-sided bound on adjacent differences would suffice as well, but is stronger
than needed.

For bootstrap percolation the first condition is already Morris's Lemma 7
(2009). Stage 3 gives its boundary construction and completes the common-slope
argument in `fixed_width_common_growth.md`. The previous version of this note
mistakenly treated dimension monotonicity as unresolved. No separate
bounded-loss extension conjecture is needed.

The height-four vector certificate already gives `E(4,n+3)=E(4,n)+2` for
all `n >= 19`; the checked finite prefix gives the formula from `n=5`.
The general argument here neither changes nor independently revalidates that
specific semantic graph.

## 5. Reproducible arithmetic checks

`experiments/semilinear_growth.jl` implements Lemma 2 and the exact crossover
calculation in Section 3. It accepts an explicitly supplied semilinear
description and returns residue formulas, valid thresholds, and finite
generator witnesses. It uses integer arithmetic, including `BigInt` for weights,
length offsets, and crossovers. The period has a configurable resource limit.

The implementation does not discover the bootstrap spectrum or infer a proof
from a finite list of `E(h,n)` values. It validates the arithmetic mechanism
used in the proof once a spectrum description is supplied.

Tests compare the formulas against an independent bounded-length dynamic
program. They cover missing residues, equal-density generators, zero weights,
different slopes by parity, delayed crossovers, finite families, and large
integers. Run them with:

```text
julia -e 'using Test; include("test/semilinear_growth.jl")'
```

## Attribution and research status

The semilinear framework is classical. See Ginsburg and Spanier,
"Semigroups, Presburger formulas, and languages," Pacific Journal of
Mathematics 16 (1966), 285-296:

<https://doi.org/10.2140/pjm.1966.16.285>

The independent closure proof in Section 1 specializes the familiar regular
language argument to the two coordinates needed here. Related general
max-plus matrix theory is developed by Sergeev and Schneider,
"CSR expansions of matrix powers in max algebra," Transactions of the AMS
364 (2012), 5969-5994:

<https://arxiv.org/abs/0912.2534>

Focused searches on 2026-10-14 for fixed-width minimal percolating sets,
eventual periodicity, and automata did not locate this bootstrap-specific
statement. That is insufficient to establish novelty; bounded-width logical
and automata methods may imply it elsewhere. The strongest concrete candidate
contribution remains the exact height-four formula once its semantic graph is
fully audited. Stage 3 subsequently resolved the single-slope question using
Morris's known monotonicity lemma. The remaining priorities are that graph
audit, a concise paper draft, and a more complete novelty review.
