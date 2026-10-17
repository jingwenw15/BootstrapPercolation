# Width-Four Semantic Certificate Audit

## Outcome

The full exported height-four graph has now passed an independent semantic
audit. This closes the previously recorded trust boundary between the
mathematical frontier model and the graph supplied to the arithmetic checker.

The combined semantic and arithmetic verification supports the
computer-assisted theorem

```text
E(4,4) = 5,
E(4,n) = floor((2n+10)/3) for every n >= 5.
```

The checker is `experiments/check_width4_semantic_certificate.jl`. It imports
the standalone arithmetic checker, which also uses only Base Julia. Neither
checker imports the simulator, the packed frontier implementation, the
production graph generator, or the generic reference implementation.

## What is independently checked

The input consists of the two semantic graph tables and the two compact
arithmetic tables already committed in `experiments/results/`.

1. Decode every semantic frontier into an ordinary `BitSet`, using a different
   frontier numbering from the production bitset layout. Verify the state and
   obligation counts, reject duplicate semantic states, and build a new index.
2. Check every labeled edge's weight against its seed-column population.
   Match each projected edge to the compact arithmetic certificate, binding
   the semantic and arithmetic state IDs to the same graph.
3. Independently generate every prefix through the first three columns and
   compare the exact maximum starting score at every exported vertex. There
   are 496 distinct warm-up states; no other state may have an initial score.
4. Independently compute right-boundary acceptance at every exported state.
5. For each of the 26,009 states, try all sixteen possible new seed columns.
   Recompute stable-set and deletion-witness updates directly from the
   neighbor-count definition. Require each legal successor to be present with
   the correct target, and each rejected successor to have no edge.
6. Check forward reachability of every vertex from the verified starting
   states. Then run the standalone arithmetic checker on those same IDs.

The results are:

```text
semantic states                         26,009
legal labeled transitions              114,602
state/column choices checked           416,144
rejected state/column choices           301,542
warm-up states                             496
right-accepting states                   8,924
boundary-core states                    15,150
boundary-core edges                     46,618
score-vector recurrence            v_22 = v_19 + 2
```

The initial exported tables contain only 1,732 distinct frontier sets, so
memoizing the independent set updates makes the complete check inexpensive.
This cache stores exact sets; it introduces no search approximation.

## Why this proves completeness of the supplied graph

Let `W` be the independently computed set of three-column states and `G` the
exported semantic graph. The warm-up check gives exact equality of starting
states and their best scores. The universal transition check says that for
every exported vertex and every input column, the exported transition is
exactly the one specified by the independent semantic model, including
rejection. In particular `G` is closed under every legal successor.

Induction on the number of further columns therefore shows that every legal
semantic path from `W` is represented in `G`. Conversely, every edge in `G`
has the specified semantics. Forward reachability rules out additional
unreachable vertices. Thus `G` is precisely the reachable stationary graph of
this model, not a sample of it or a potentially truncated exploration.

The acceptance and edge-weight checks identify its accepted maximum-weight
paths with the objective in `notes/fixed_width_state_theorem.md`. The compact
edge projection binds that graph to the arithmetic certificate. Consequently
the standalone recurrence calculation applies to the percolation problem
itself, rather than merely to an unverified supplied graph.

## Tests and reproduction

`test/width4_semantic_certificate.jl` additionally checks the new semantic
implementation against direct synchronous bootstrap closure on every
configuration of `4 x 1`, `4 x 2`, `4 x 3`, and `4 x 4`: 69,904 configurations
in total. This comparison includes every seed deletion required for minimality.

Negative tests deliberately remove, redirect, and add transitions, alter a
starting score and an accepting flag, corrupt hexadecimal frontiers, give an
incorrect seed weight, and mismatch the arithmetic edge table. Each corruption
must be rejected. These tests support the checker's implementation; the
graph-completeness argument is the induction above together with the
mathematical model's soundness/completeness proof.

Run the full standalone audit and save its computed report with:

```text
julia experiments/check_width4_semantic_certificate.jl \
  experiments/results/width4_semantic_certificate.txt
```

Run its regression suite independently with:

```text
julia -e 'using Test; include("experiments/fast_exact.jl"); include("test/width4_semantic_certificate.jl")'
```

Both `julia test/runtests.jl` and the research verifier also include the audit.

## Remaining scope

This is a computer-assisted proof, with a written mathematical reduction and
two separately implemented semantic engines. It still relies on the stated
mathematical argument and ordinary Julia execution; it is not a Lean proof.
External mathematical review and a broader novelty review remain useful before
publication. No claim that the exact formula is new is established by this audit.
