# Review Draft

The self-contained manuscript is [manuscript.md](manuscript.md). It states
the fixed-height eventual recurrence, proves it using regular languages,
semilinearity, and Morris's monotonicity lemma, and gives the independently
checked height-four formula and construction.

The counting supplement also gives certified recurrences for the number of
height-four maximizing seed sets in each width class modulo three. Its proof,
scope, and common degree-14 polynomial are explained in
[width4_maximizer_counts.md](../notes/width4_maximizer_counts.md). Regenerate
the exact-integer recurrence artifact with:

```text
julia experiments/certify_width4_counts.jl
```

The structural supplement proves that every height-four minimal percolating
set has at most four multiple-seed columns, with no maximum-size assumption.
See [width4_crowded_columns.md](../notes/width4_crowded_columns.md). Reproduce
its rank certificate and sharp witnesses with:

```text
julia experiments/width4_crowded_columns.jl
```

The upper bound also has a direct geometric proof, independent of that
certificate, in [width4_crowded_hand_proof.md](../notes/width4_crowded_hand_proof.md).
It gives a necessary two-three-row-rectangle structure for equality. The
sharp finite example has explicit stable deletion forts, checked locally
without simulation. The infinite family still uses its separate pumping
certificate.

The height-five extension is [height5_crowding.md](../notes/height5_crowding.md):
the crowded-column bound is eight and is attained at width 35. Regenerate
the sharp witness's local deletion
certificates with:

```text
julia experiments/height5_crowding.jl
```

The next extension, [height6_crowding.md](../notes/height6_crowding.md), proves
the sharp height-six bound sixteen and identifies the first unbounded
crowding height as seven. The upper endpoint uses Gottschau's existing
height-seven construction, now checked against the original PDF. Reproduce
the `6 x 75` sharp witness and its 54 local deletion certificates with:

```text
julia experiments/height6_crowding.jl
```

[verified_results.md](verified_results.md) is computed from the complete
semantic and arithmetic certificate. It contains the finite prefix, graph
counts, independent construction-loop checks, and SHA-256 digests of the four
certificate inputs. Regenerate it from the repository root with:

```text
julia experiments/prepare_paper.jl
```

The semantic/arithmetic checker and `prepare_paper.jl` require only Julia's
Base and standard library. They do not execute the original search or
optimized state generator. The crowded-column generator and full simulator
regression suite also use the project's existing `DataStructures` dependency:

```text
julia test/runtests.jl
```

## Review Questions

1. Is the exact all-length formula for `E(4,n)` already known, including in
   work citing Gottschau's dissertation?
2. Is eventual affine periodicity of `E(h,n)` for every fixed `h` already
   stated or an immediate published consequence of bounded-width methods?
3. Are the stable-set language and the one-seed-deletion language defined
   correctly, including both open boundaries?
4. Does the concrete state invariant justify the early rejection, completed
   witness removal, and merging of equal future obligations?
5. Is the combination of the semantic audit and arithmetic certificate an
   adequate reproducible computational proof for the intended venue?
6. Are the exact maximizer-count recurrences known, and is there a geometric
   explanation of their common polynomial and residue-dependent powers?
7. Is the sharp four-crowded-column bound for all height-four minimal sets
   already known, and are the strip lemma, mixed-column cases, and equality
   argument in the new geometric proof correct?
8. Is the sharp height-five bound of eight known, and is the new separated
   two-row bridge lemma sound? Has the smallest-unbounded-height question
   already been resolved under different terminology?
9. Are the height-six three-row overlap argument and the sharp bound of
   sixteen correct, and is the resulting threshold of seven already known?
   The height-seven construction itself must be credited to Gottschau.

The manuscript is a working draft for mathematical and priority review.
Dimension monotonicity belongs to Morris, and the automata/semilinear tools
are classical. Values through length eleven were already reported by
Gottschau. The possible contributions are the exact all-length height-four
formula with its certificate and the explicit fixed-height structural result;
the counting and crowded-column supplements are further candidate
contributions. None of these novelty claims has been established by the
searches so far.
