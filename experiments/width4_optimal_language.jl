if !@isdefined(Width4SemanticCertificate)
    include("check_width4_semantic_certificate.jl")
end

function width4_semantic_warmup_counts!(audit)
    checker = Width4SemanticCertificate
    initial = (0, 0, checker.intern!(audit.context, BitSet([0])), ())
    current = Dict(initial => (0, big(1)))
    for phase in 0:2
        next = Dict{checker.SemanticState, Tuple{Int, BigInt}}()
        for (state, (score, ways)) in current, column in 0:15
            target = checker.semantic_transition!(audit.context, state, column, phase)
            target === nothing && continue
            candidate = score + count_ones(column)
            old_score, old_ways = get(next, target, (checker.CERTIFICATE_NEGATIVE_INFINITY, big(0)))
            if candidate > old_score
                next[target] = (candidate, ways)
            elseif candidate == old_score
                next[target] = (candidate, old_ways + ways)
            end
        end
        current = next
    end
    scores = fill(checker.CERTIFICATE_NEGATIVE_INFINITY, length(audit.states))
    counts = [big(0) for _ in audit.states]
    for (state, (score, ways)) in current
        id = audit.ids[state]
        scores[id], counts[id] = score, ways
    end
    scores == audit.initial_scores || error("warm-up scores disagree with certificate")
    return scores, counts
end

function width4_advance_optimal_counts(audit, scores, counts, core)
    neg = Width4SemanticCertificate.CERTIFICATE_NEGATIVE_INFINITY
    next_scores = fill(neg, length(scores))
    next_counts = [big(0) for _ in scores]
    for source in eachindex(scores)
        core[source] && scores[source] != neg || continue
        for column in 0:15
            target = audit.targets[source, column + 1]
            target != 0 && core[target] || continue
            candidate = scores[source] + count_ones(column)
            if candidate > next_scores[target]
                next_scores[target] = candidate
                next_counts[target] = counts[source]
            elseif candidate == next_scores[target]
                next_counts[target] += counts[source]
            end
        end
    end
    return next_scores, next_counts
end

"""
Build the stationary, labeled language of optimal continuations after column 19.
Phase p=1,2,3 denotes lengths 19,20,21 modulo three. An edge is retained iff
it attains the optimal prefix score at its target. Right-boundary acceptance
also requires the global optimal score. Counts distinguish all seed words,
without identifying rotations or reflections.
"""
function width4_optimal_language(audit; verify = true)
    checker = Width4SemanticCertificate
    verify && checker.verify_loaded_semantic_certificate!(audit)
    size = length(audit.states)
    core = checker.reverse_reachable_vertices(size, audit.edges, audit.accepting)
    scores, counts = width4_semantic_warmup_counts!(audit)
    scores[.!core] .= checker.CERTIFICATE_NEGATIVE_INFINITY
    counts[.!core] .= big(0)
    profiles = Vector{Int}[]
    initial_counts = BigInt[]
    prefix = NamedTuple[]
    for n in 3:22
        best = maximum(scores[audit.accepting])
        ways = sum(counts[id] for id in eachindex(scores) if audit.accepting[id] && scores[id] == best)
        push!(prefix, (cols = n, maximum_size = best, maximizing_count = ways))
        if n == 19
            initial_counts = copy(counts)
        end
        19 <= n <= 21 && push!(profiles, copy(scores))
        n == 22 && break
        scores, counts = width4_advance_optimal_counts(audit, scores, counts, core)
    end
    checker.certificate_vectors_differ_by(profiles[1], scores, core, 2) ||
        error("the optimal-edge graph is not stationary with period three")

    edges = NamedTuple{(:from, :to, :column), Tuple{Int, Int, Int}}[]
    accepting = falses(3 * size)
    neg = checker.CERTIFICATE_NEGATIVE_INFINITY
    for phase in 1:3
        following = mod(phase, 3) + 1
        gain = phase == 3 ? 2 : 0
        best = maximum(profiles[phase][audit.accepting])
        for source in 1:size
            core[source] && profiles[phase][source] != neg || continue
            id = (phase - 1) * size + source
            accepting[id] = audit.accepting[source] && profiles[phase][source] == best
            for column in 0:15
                target = audit.targets[source, column + 1]
                target != 0 && core[target] || continue
                profiles[following][target] != neg || continue
                profiles[phase][source] + count_ones(column) == profiles[following][target] + gain || continue
                push!(edges, (from = id, to = (following - 1) * size + target, column = column))
            end
        end
    end
    useful = checker.reverse_reachable_vertices(3 * size, edges, accepting)
    starts = fill(neg, 3 * size)
    for id in 1:size
        initial_counts[id] > 0 && (starts[id] = 0)
    end
    useful .&= checker.forward_reachable_vertices(3 * size, edges, starts)
    ids = findall(useful)
    compact = zeros(Int, 3 * size)
    compact[ids] .= eachindex(ids)
    trimmed = [(from = compact[e.from], to = compact[e.to], column = e.column)
               for e in edges if useful[e.from] && useful[e.to]]
    weights = [id <= size ? initial_counts[id] : big(0) for id in ids]
    return (audit = audit, ids = ids, edges = trimmed, accepting = accepting[ids],
            initial_counts = weights, prefix = prefix, profiles = profiles)
end

function width4_optimal_language_counts(language, last_col)
    last_col >= 19 || throw(ArgumentError("last_col must be at least 19"))
    counts = copy(language.initial_counts)
    rows = NamedTuple[]
    for n in 19:last_col
        push!(rows, (cols = n, maximizing_count = sum(counts[language.accepting])))
        n == last_col && break
        following = [big(0) for _ in counts]
        for edge in language.edges
            following[edge.to] += counts[edge.from]
        end
        counts = following
    end
    return rows
end

"""Exact counting quotient; labels are forgotten, but edge multiplicities remain."""
function width4_optimal_count_quotient(language)
    size = length(language.accepting)
    adjacency = [Int[] for _ in 1:size]
    for edge in language.edges
        push!(adjacency[edge.from], edge.to)
    end
    blocks = Int.(language.accepting) .+ 1
    rounds = 0
    while true
        signatures = Dict{Tuple{Int, Tuple{Vararg{Int}}}, Int}()
        refined = zeros(Int, size)
        for id in 1:size
            signature = (blocks[id], Tuple(sort!([blocks[target] for target in adjacency[id]])))
            refined[id] = get!(signatures, signature, length(signatures) + 1)
        end
        rounds += 1
        stable = length(signatures) == length(unique(blocks))
        blocks = refined
        stable && break
    end
    block_count = maximum(blocks)
    representatives = zeros(Int, block_count)
    counts = [big(0) for _ in 1:block_count]
    for id in 1:size
        block = blocks[id]
        representatives[block] = id
        counts[block] += language.initial_counts[id]
    end
    edges = NamedTuple{(:from, :to, :multiplicity), Tuple{Int, Int, Int}}[]
    for block in 1:block_count
        multiplicities = Dict{Int, Int}()
        for target in adjacency[representatives[block]]
            destination = blocks[target]
            multiplicities[destination] = get(multiplicities, destination, 0) + 1
        end
        for destination in sort!(collect(keys(multiplicities)))
            push!(edges, (from = block, to = destination, multiplicity = multiplicities[destination]))
        end
    end
    return (blocks = blocks, edges = edges, initial_counts = counts,
            accepting = language.accepting[representatives], rounds = rounds)
end

function width4_quotient_counts(quotient, last_col)
    last_col >= 19 || throw(ArgumentError("last_col must be at least 19"))
    counts = copy(quotient.initial_counts)
    rows = NamedTuple[]
    for n in 19:last_col
        push!(rows, (cols = n, maximizing_count = sum(counts[quotient.accepting])))
        n == last_col && break
        following = [big(0) for _ in counts]
        for edge in quotient.edges
            following[edge.to] += edge.multiplicity * counts[edge.from]
        end
        counts = following
    end
    return rows
end

if abspath(PROGRAM_FILE) == @__FILE__
    audit = Width4SemanticCertificate.load_semantic_certificate()
    language = width4_optimal_language(audit)
    println("trimmed optimal-language states = ", length(language.ids))
    println("trimmed labeled edges = ", length(language.edges))
    quotient = width4_optimal_count_quotient(language)
    println("counting quotient states = ", length(quotient.accepting))
    println("counting quotient edges = ", length(quotient.edges))
    for row in width4_quotient_counts(quotient, isempty(ARGS) ? 40 : parse(Int, ARGS[1]))
        println(row.cols, ",", row.maximizing_count)
    end
end
