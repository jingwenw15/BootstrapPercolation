# Review Draft

The self-contained manuscript is [manuscript.md](manuscript.md). It states
the fixed-height eventual recurrence, proves it using regular languages,
semilinearity, and Morris's monotonicity lemma, and gives the independently
checked height-four formula and construction.

[verified_results.md](verified_results.md) is computed from the complete
semantic and arithmetic certificate. It contains the finite prefix, graph
counts, independent construction-loop checks, and SHA-256 digests of the four
certificate inputs. Regenerate it from the repository root with:

```text
julia experiments/prepare_paper.jl
```

The checker and paper-data generator require only Julia's Base and standard
library. They do not execute the original search or optimized state generator.
The full simulator regression suite additionally uses the project's existing
`DataStructures` dependency:

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

The manuscript is a working draft for mathematical and priority review.
Dimension monotonicity belongs to Morris, and the automata/semilinear tools
are classical. Values through length eleven were already reported by
Gottschau. The possible contributions are the exact all-length height-four
formula with its certificate and the explicit fixed-height structural result;
their novelty has not been established by the searches so far.
