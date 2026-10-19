# Largest Minimal Percolating Sets on Fixed-Height Grids

Working draft for mathematical and priority review, 2026-10-18.

## Abstract

For two-neighbor bootstrap percolation on the open `h x n` square grid,
write `E(h,n)` for the largest size of an inclusion-minimal percolating
initial set. For each fixed height we prove an effective eventual recurrence
`E(h,n+p)=E(h,n)+q`, and hence the existence of a rational limiting density.
The proof combines a finite-language description of minimal percolating sets,
semilinearity, and Morris's dimension-monotonicity theorem. For height four,
we give a computer-assisted proof of `E(4,4)=5` and
`E(4,n)=floor((2n+10)/3)` for every `n >= 5`. Separate implementations verify
the complete semantic state graph and its maximum-weight recurrence. An
explicit family attaining the bound adds two seeds per three columns.

## 1. Model, Results, and Attribution

Let `G(h,n)` have vertex set `[h] x [n]`, with edges between orthogonally
adjacent vertices. Neighbors beyond the boundary are absent. Starting from
`A_0=A`, let

```text
A_(t+1) = A_t union {v : v has at least two neighbors in A_t}.
```

Infection is permanent, and updates are synchronous. Write `[A]` for the
eventual infected closure. A set percolates when `[A]=V(G)`, and is
inclusion-minimal percolating when deleting any one of its seeds destroys
percolation. This single-deletion definition agrees with minimality under
arbitrary proper subsets because closure is monotone in the initial set.
Define

```text
E(h,n) = max {|A| : A is inclusion-minimal percolating on G(h,n)}.
```

Such sets exist for every positive `h,n`: start with the entire grid infected
and repeatedly delete a seed whenever percolation survives.

**Theorem A (fixed height).** For every positive integer `h`, there are
effectively computable integers `p_h > 0`, `q_h >= 0`, and `N_h` such that

```text
E(h,n+p_h) = E(h,n)+q_h  for all n >= N_h.
```

In particular, `E(h,n) = rho_h*n + beta_(n mod p_h)` eventually, for a
rational number `rho_h=q_h/p_h` and rational periodic corrections `beta_r`.
The eventual first differences are nonnegative and periodic.

**Theorem B (height four; computer-assisted).**

```text
E(4,4) = 5,
E(4,n) = floor((2n+10)/3)  for every n >= 5.
```

Morris [M] introduced the extremal parameter and determined the exact values
for heights at most three. His Lemma 7 establishes monotonicity in both
dimensions; that is an essential existing ingredient in Theorem A. Gottschau
[G, Lemma 55 and Remark 56] gives the bound `E(4,n) <= 4n/5+12/5` and exact
height-four values through length eleven. Our small cases through eleven
therefore confirm prior values. The regular-language and semilinear tools
used below are classical, as in [GS].

The purpose of this draft is to expose the mathematical and computational
arguments for review. It makes no priority claim for Theorem A or B; the
literature checks so far have not established novelty.

## 2. Stable Sets and Deletion Witnesses

Call a nonempty vertex set `S` stable if every vertex of `S` has at most one
neighbor outside `S`. The degree here is its actual degree in the finite grid.

**Lemma 1.** A seed set `A` percolates if and only if no stable set avoids `A`.
It is minimal percolating if and only if additionally every `a in A` has a
stable set `S_a` satisfying `S_a intersect A = {a}`.

**Proof.** A stable set disjoint from the seeds cannot acquire its first
infection, since any such vertex would need two infected neighbors outside
the set. Conversely, the nonempty healthy remainder of a failed process is
stable: a healthy vertex with two neighbors outside the remainder would have
been infected. This proves the first assertion.

Apply it to `A without {a}`. A stable obstruction avoids the remaining seeds.
If `A` percolates it cannot also avoid `a`, so its intersection with `A` is
exactly `{a}`. The converse follows by applying the same argument to every
single deletion. QED.

## 3. Regularity for Every Fixed Height

Represent a seed set as a word `B_1 ... B_n` over the finite alphabet
`Sigma_h = {subsets of [h]}`, where `B_j` records its seeds in column `j`.
All languages in this section contain positive-length words only.

**Lemma 2.** For fixed `h`, the language of minimal percolating seed words is
regular, with an effectively constructible finite automaton.

**Proof.** First consider pairs of words `(B_1...B_n, U_1...U_n)`, where
`U_j` describes the cells of a potential stable set in column `j`. Requiring
`U_j intersect B_j = empty` is a condition on the current pair of letters.
Requiring nonemptiness needs one Boolean flag. Stability at column `j`
depends only on `U_(j-1),U_j,U_(j+1)`: when the next letter is read, all
neighbors of cells in `U_j` are known. Two stored column patterns therefore
suffice. A finite phase distinguishes the left boundary, and the terminal
check omits nonexistent right neighbors.

Thus stable obstructions are recognized by a finite automaton on pairs of
letters. Forget the `U` component, or equivalently guess it nondeterministically.
The resulting regular language `F_h` consists exactly of nonpercolating seed
words by Lemma 1. Its complement in `Sigma_h^+`, denoted `P_h`, is therefore
regular and consists exactly of percolating words.

Let `D_h` contain those words for which some single seed deletion lies in
`P_h`. A finite automaton recognizes `D_h` by guessing exactly one input
position and one of the at most `h` seeds in that position, feeding the
modified column to a deterministic automaton for `P_h`, and feeding every
other column unchanged. A flag ensures that exactly one seed was deleted.
This is a finite construction. Finally, the desired language is
`P_h without D_h`, a regular language. QED.

This proof of regularity does not rely on the computational state compression
used in Section 6. It also shows that no bound on infection times is needed.

## 4. From a Regular Language to Eventual Growth

For fixed `h` define the spectrum

```text
S_h = {(n,s) : some minimal percolating set on G(h,n) has s seeds}.
```

A set of nonnegative integer vectors is linear if it has the form
`b + monoid(P)` for a finite generator set `P`, and semilinear if it is a
finite union of such sets.

**Lemma 3.** The additive image of a regular language is effectively
semilinear. In particular, `S_h` is effectively semilinear.

**Proof.** Convert a finite automaton to a regular expression. Union of
semilinear sets remains semilinear, and addition of linear sets adds their
bases and takes the union of their generators. For the star operation, if

```text
S = union_(i=1)^m (b_i + monoid(P_i)),
```

then the additive closure `S*` is `{0}` together with the union, over nonempty
subsets `I` of `{1,...,m}`, of

```text
sum_(i in I) b_i + monoid({b_i : i in I} union union_(i in I) P_i).
```

Here `I` records which families supply a summand. Reserve one base from each
such family, then assign all its generator contributions to that summand;
further summands contribute further copies of its base. This proves both
inclusions. Induction through the expression proves the claim. For `S_h`,
map a seed letter `B` to `(1,|B|)` and use Lemma 2. QED.

All points of `S_h` satisfy `0 <= s <= h*n`. Hence every nonzero generator
in a semilinear representation has positive length: a generator `(0,w)` with
`w>0` would give infinitely many sizes at a fixed length. Zero generators
can be discarded.

**Lemma 4.** The maximum size in `S_h` is eventually affine separately on
each residue class of an effective common period.

**Proof.** Consider one infinite linear family with base `(a,b)` and
generators `(l_i,w_i)`, where `l_i>0`. Choose a generator `(p,g)` of maximum
ratio `g/p`, and set `d_i=g*l_i-p*w_i >= 0`. A combination of generator
length `L` and weight `W` has loss `D=g*L-p*W`.

For each reachable residue `r modulo p`, choose a combination of minimum
loss `D_r`, and among those one of minimum length `L_r`. These minima exist
in the nonnegative integers. Every combination at this residue has loss at
least `D_r`. For any `L>=L_r` at this residue, adding `(L-L_r)/p` copies of
`(p,g)` to the selected combination achieves that minimum loss. Thus its
maximum weight is exactly `(g*L-D_r)/p`.

Both minima are effective: on the finite residue graph modulo `p`, a
generator gives an edge of displacement `l_i` and lexicographic cost
`(d_i,l_i)`. A minimum-cost path can be simple, since deleting a cycle never
increases loss and strictly shortens length. Exhausting simple paths suffices.

Take a common period `P` divisible by the chosen `p` for every infinite
family. On any residue `n=P*k+r`, each family is eventually absent or has
maximum `Q_i*k+B_i`, with integer `Q_i=P*g_i/p_i`. Singleton families
disappear after their sole lengths. The maximum of finitely many affine
functions is eventually the one with largest slope, then largest intercept;
the finitely many crossing thresholds are effective. Since a minimal
percolating set exists at every positive length, no residue is eventually
absent from `S_h`. QED.

The semilinear conversion is finite but need not be computationally practical.
Theorem A asserts effectivity, not a small uniform state bound or efficient
computation as the height varies.

## 5. Monotonicity and the Common Gain

We use Morris's monotonicity lemma [M, Lemma 7]. For completeness, the
boundary argument can be expressed in terms of closure as follows.

Suppose `T` contains the old boundary seed `a=(r,n)`, and let `H=[T]` in
`G(h,n)`. Add a column and the single seed `b=(r,n+1)`. Let `I` be the
maximal interval of rows containing `r` for which `(s,n)` belongs to `H`.
The set `H` together with the new cells at rows in `I` is closed in the
enlarged grid. An old cell outside `H` gains no new infected neighbor. A new
cell adjacent to `I` has its old neighbor outside `H`, by maximality, and at
most one infected vertical neighbor. Any other new cell outside `I` has at
most its old neighbor infected. Thus the added column cannot enlarge the
closure within the old rectangle.

Now take a minimal percolating `A` and choose a seed `a` in its last column;
that column cannot have been empty. With `b` its new neighbor, put
`B=A union {b}` and `C=(A without {a}) union {b}`. The set `B` percolates.
If `C` percolates, deleting its new seed leaves an empty new column, and
deleting any other seed fails by the preceding closure argument and
minimality of `A`. Thus `C` is minimal. If `C` fails, `B` is minimal by
the same argument, with deletion of `a` handled by that failure. Their sizes
are `|A|` and `|A|+1`, respectively. In particular `E(h,n+1)>=E(h,n)`.

**Proof of Theorem A.** By Lemma 4 write, eventually,

```text
E(h,pk+r) = q_r*k+b_r,  0 <= r < p.
```

Monotonicity forces `q_r <= q_(r+1)` for consecutive residues: otherwise the
inequality of adjacent values fails for large `k`. At the wraparound,
`E(h,pk+p-1) <= E(h,p(k+1))` forces `q_(p-1) <= q_0`. Consequently all
gains equal one integer `q`. Taking a threshold beyond every residue's
finite prefix proves the recurrence. Division by `pk+r` gives the common
rational limit; the periodic-correction and first-difference assertions follow
from the residue formulas. QED.

## 6. The Concrete Witness Automaton

To obtain the height-four certificate we use the following deterministic
implementation of Lemma 1. A stable frontier after column `j` consists of
`(L,C,e)`: stable-set patterns in columns `j-1,j`, and a flag recording any
nonempty stable column. All stable-set conditions before column `j` have
already been checked. There are `2^(2h+1)` possible frontiers for fixed `h`.

After reading seeds through column `j`, store the last two seed patterns,
a set `Z` of all frontiers avoiding the processed seeds, and a set `O` of
unresolved deletion obligations. Each obligation is a set of frontiers for
partial stable sets meeting the processed seeds exactly at its particular
deleted seed. Initially the only avoiding frontier is `(empty,empty,false)`,
and there are no obligations.

For a new seed column `B`, update as follows:

1. Advance `Z` through every stable-column pattern disjoint from `B`.
2. Advance every old obligation in the same way.
3. For each seed `b in B`, advance the old `Z` through stable-column patterns
   meeting `B` exactly at `{b}`, creating its new obligation.
4. Drop any obligation having a legal completion with all subsequent stable
   columns empty. Reject any unresolved obligation with no frontier.
5. Reject if `Z` has a nonempty stable completion with all subsequent columns
   empty. Merge obligations with identical frontier sets.

The frontier transitions check the previous stable column once both adjacent
patterns are known. Ordinary transitions treat a next column as existing;
the terminal check omits nonexistent right neighbors. A finite phase handles
the first two columns and the missing left neighbor.

Steps 1-3 give exact frontier sets by induction. A completed witness has no
vertices in the unread suffix and therefore remains a valid witness for every
future seed word. An empty obligation can never be repaired. Similarly a
completed seed-avoiding stable set prevents percolation for every suffix.
Equal obligations have identical predicates on every future suffix, and the
same suffix may satisfy both using separate witnesses, so they can be merged.

The search also rejects a seed having two initially infected neighbors. After
its deletion it is infected in the first round, so its deletion cannot
destroy percolation. This local test removes no minimal percolating set; the
last two seed columns suffice to apply it when a column is finalized.

At the terminal boundary, accept precisely when no nonempty stable frontier
from `Z` closes and every remaining obligation has a closing witness. By
Lemma 1, these are exactly the minimal percolating seed words. The word's
weight is its seed count. Sorting and deduplicating sets changes no predicate.

## 7. Height-Four Certificate and Exact Formula

The exported stationary graph follows three warm-up columns. Its independent
semantic audit verifies the following computed quantities:

| Quantity | Value |
|---|---:|
| Semantic states | 26,009 |
| Labeled edges | 114,602 |
| State/column choices checked | 416,144 |
| Warm-up states | 496 |
| Right-accepting states | 8,924 |
| States that can reach acceptance | 15,150 |
| Edges between those states | 46,618 |

Each exported state and each of the sixteen possible seed columns is checked
against a separate set-based implementation of Section 6. The audit checks
rejected transitions as well as legal ones, every initial maximum score, every
accepting flag, and the projection of labeled edges to the arithmetic tables.
It also checks reachability of every vertex. Thus the exported graph is
exactly the reachable stationary graph, rather than a possibly truncated
exploration. The audit does not import the original transition generator.

Restrict to vertices that can reach an accepting right boundary. This
restriction is essential: the full graph contains a larger-weight cycle in
a component that cannot reach acceptance. Let `v_n(s)` be the maximum number
of seeds in a length-`n` prefix reaching retained state `s`, using negative
infinity for unreachable states. If `T` is the stationary maximum-weight
transition operator, then `v_(n+1)=T(v_n)`.

The exact integer checker computes

```text
v_22(s) = v_19(s)+2
```

at every retained state, including matching unreachable entries. Since
`T(v+2)=T(v)+2`, induction gives `v_(n+3)=v_n+2` for every `n>=19`.
Taking the maximum over accepting states gives the same recurrence for
`E(4,n)`.

For reference, the independently verified finite values are:

```text
n:       4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22
E(4,n):  5  6  7  8  8  9 10 10 11 12 12 13 14 14 15 16 16 17 18
```

**Proof of Theorem B.** The finite values give `E(4,4)=5` and match the
claimed formula for `5<=n<=22`. The checked vector equality proves a gain
of two every three columns from length nineteen onward. The same gain holds
for `floor((2n+10)/3)`, covering all remaining lengths. QED.

This is a computer-assisted proof: the universal semantic checks and the
integer vector comparison are finite computations, supplied with executable
checkers and their input data. They are not an induction inferred from a
finite numerical pattern.

## 8. Explicit Maximizing Sets

Encode a seed column by `sum_(r=1)^4 2^(r-1) * 1_(row r is seeded)`; row one
is the top row. For every `n>=9`, concatenate a left boundary, copies of
the block `[1,1,0]`, and the suffix `[2,10,8,0,1,5,4]`:

| n mod 3 | Left boundary | Copies of the block |
|---:|---|---:|
| 0 | `[2,0]` | `(n-9)/3` |
| 1 | empty | `(n-7)/3` |
| 2 | `[2,0,1,0]` | `(n-11)/3` |

These words have the required length and `floor((2n+10)/3)` seeds. The
independent checker verifies that after the left boundary and one block,
adding another block returns the complete semantic state to itself, and the
fixed suffix is accepting. The length-9, length-10, and length-11 base words
are separately accepted. Stationarity and induction therefore prove minimal
percolation for every specified length. This construction proof is also
computer-assisted; it does not assert a separate hand classification of all
deleted-seed witnesses. The complete-loop checks are regenerated by
`experiments/prepare_paper.jl`.

## 9. Reproduction and Computational Scope

The four certificate tables in `experiments/results/` are:

```text
width4_interior_graph_states.csv
width4_interior_graph_transitions.csv
width4_boundary_certificate_vertices.csv
width4_boundary_certificate_edges.csv
```

From the repository root run:

```text
julia experiments/prepare_paper.jl
```

This runs `check_width4_semantic_certificate.jl` and its separate arithmetic
checker, verifies the three construction loops, and regenerates
[verified_results.md](verified_results.md). That report gives the computed
finite prefix, graph statistics, Julia version, and SHA-256 digests of the
exact four input tables. The digests identify the artifacts; they are not
used in place of semantic verification. The checkers require only Base Julia;
the report generator additionally uses Julia's standard SHA library.

The full test suite is `julia test/runtests.jl`. Among its checks, the separate
semantic implementation agrees with direct synchronous bootstrap closure on
every configuration of `4 x 1` through `4 x 4`, including each single-seed
deletion required for minimality. Mutation tests reject incorrect transitions,
weights, starting scores, accepting labels, and malformed frontier encodings.
The simulator preserves the input grid and records synchronous history.

These tests corroborate the implementations. The correctness argument for
all lengths is the state invariant, universal finite graph checks, and vector
recurrence. No formula or density for height five is claimed here. Mathematical
review of the reduction, computational review of the checkers, and priority
review of both principal results remain appropriate before submission.

## References

[M] Robert Morris. Minimal Percolating Sets in Bootstrap Percolation.
Electronic Journal of Combinatorics 16 (2009), #R2.
<https://doi.org/10.37236/91>.

[G] Marinus Christopher Johannes Gottschau. Cuts, Paths, and Processes in
Graphs. Doctoral dissertation, Technical University of Munich, 2020.
Section 3.1.3, Lemma 55 and Remark 56.
<https://d-nb.info/1220423823>.

[GS] Seymour Ginsburg and Edwin H. Spanier. Semigroups, Presburger formulas,
and languages. Pacific Journal of Mathematics 16 (1966), 285-296.
<https://doi.org/10.2140/pjm.1966.16.285>.
