module SemilinearGrowth

export LengthWeightFamily, certify_semilinear_growth, eventual_value, exact_values

struct LengthWeightFamily
    base_length::BigInt
    base_weight::BigInt
    generators::Vector{Tuple{Int, BigInt}}

    function LengthWeightFamily(base, generators = [])
        a, b = BigInt.(base)
        a >= 0 && b >= 0 || throw(ArgumentError("base coordinates must be nonnegative"))
        periods = Tuple{Int, BigInt}[]

        for (length, weight) in generators
            length > 0 || throw(ArgumentError("generator lengths must be positive"))
            weight >= 0 || throw(ArgumentError("generator weights must be nonnegative"))
            push!(periods, (Int(length), BigInt(weight)))
        end

        return new(a, b, periods)
    end
end

function certify_family(family; max_residues)
    isempty(family.generators) && return nothing
    best = 1
    for i in eachindex(family.generators)
        l, w = family.generators[i]
        p, g = family.generators[best]
        w * p > g * l && (best = i)
    end
    p, g = family.generators[best]
    p <= max_residues || throw(ArgumentError("residue graph exceeds max_residues"))
    losses = [g * l - p * w for (l, w) in family.generators]

    # Lexicographic shortest paths minimize loss, then witness length.
    distances = Vector{Union{Nothing, Tuple{BigInt, BigInt}}}(nothing, p)
    distances[1] = (BigInt(0), BigInt(0))
    visited = falses(p)
    predecessor = fill((0, 0), p)

    for _ in 1:p
        vertex = 0
        for i in 1:p
            visited[i] && continue
            distances[i] === nothing && continue
            if vertex == 0 || isless(distances[i], distances[vertex])
                vertex = i
            end
        end
        vertex == 0 && break
        visited[vertex] = true
        loss, span = distances[vertex]

        for (i, (step, _)) in enumerate(family.generators)
            target = Int(mod(BigInt(vertex - 1) + step, p)) + 1
            visited[target] && continue
            candidate = (loss + losses[i], span + step)
            if distances[target] === nothing || isless(candidate, distances[target])
                distances[target] = candidate
                predecessor[target] = (vertex, i)
            end
        end
    end

    witnesses = map(eachindex(distances)) do i
        distances[i] === nothing && return nothing
        multiplicities = zeros(Int, length(family.generators))
        vertex = i
        while vertex != 1
            previous, generator = predecessor[vertex]
            multiplicities[generator] += 1
            vertex = previous
        end
        loss, span = distances[i]
        return (loss = loss, length = span, multiplicities = Tuple(multiplicities))
    end

    return (period = p, gain = g, witnesses = witnesses)
end

"""
Certify the eventual upper envelope of a finite union of length/weight families.
This accepts a supplied semilinear description; it does not extract one from
the bootstrap automaton. All weights and crossover arithmetic use BigInt.
"""
function certify_semilinear_growth(families; max_residues = 100_000)
    components = [certify_family(f; max_residues = max_residues) for f in families]
    period = BigInt(1)
    for component in components
        component === nothing && continue
        period = lcm(period, component.period)
        period <= max_residues || throw(ArgumentError("common period exceeds max_residues"))
    end
    p = Int(period)

    residues = map(0:(p - 1)) do r
        candidates = NamedTuple[]
        start = BigInt(0)
        for (family, component) in zip(families, components)
            if component === nothing
                start = max(start, cld(family.base_length + 1 - r, p))
                continue
            end
            local_residue = Int(mod(r - family.base_length, component.period))
            witness = component.witnesses[local_residue + 1]
            witness === nothing && continue
            start = max(start, cld(family.base_length + witness.length - r, p))
            gain = div(period * component.gain, component.period)
            numerator = component.period * family.base_weight +
                        component.gain * (r - family.base_length) - witness.loss
            rem(numerator, component.period) == 0 || error("nonintegral residue intercept")
            push!(candidates, (gain = gain, intercept = div(numerator, component.period)))
        end
        isempty(candidates) && return (start = start, gain = nothing, intercept = nothing)

        winner = maximum(c -> (c.gain, c.intercept), candidates)
        gain, intercept = winner
        for candidate in candidates
            candidate.gain == gain && continue
            start = max(start, cld(candidate.intercept - intercept, gain - candidate.gain))
        end
        return (start = start, gain = gain, intercept = intercept)
    end

    finite_gains = unique([r.gain for r in residues if r.gain !== nothing])
    return (
        period = p,
        residues = residues,
        components = components,
        threshold = maximum((p * row.start + r - 1 for (r, row) in enumerate(residues))),
        common_gain = length(finite_gains) == 1 ? only(finite_gains) : nothing,
    )
end

function eventual_value(certificate, n::Integer)
    n >= 0 || throw(ArgumentError("length must be nonnegative"))
    k, r = divrem(BigInt(n), certificate.period)
    row = certificate.residues[Int(r) + 1]
    k >= row.start || throw(ArgumentError("length precedes the certified residue threshold"))
    row.gain === nothing && return nothing
    return row.gain * k + row.intercept
end

"""Exact bounded-length dynamic programming, independent of residue certificates."""
function exact_values(families, last_length::Int)
    last_length >= 0 || throw(ArgumentError("last_length must be nonnegative"))
    result = Vector{Union{Nothing, BigInt}}(nothing, last_length + 1)
    for family in families
        family.base_length > last_length && continue
        base = Int(family.base_length)
        scores = Vector{Union{Nothing, BigInt}}(nothing, last_length - base + 1)
        scores[1] = family.base_weight
        for n in 0:(last_length - base)
            score = scores[n + 1]
            score === nothing && continue
            index = base + n + 1
            result[index] = result[index] === nothing ? score : max(result[index], score)
            for (length, weight) in family.generators
                n + length <= last_length - base || continue
                target = n + length + 1
                candidate = score + weight
                scores[target] = scores[target] === nothing ? candidate : max(scores[target], candidate)
            end
        end
    end
    return result
end

end
