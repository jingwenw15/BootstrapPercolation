module Width4SemanticCertificate

include("check_width4_boundary_certificate.jl")

const SemanticState = Tuple{Int, Int, Int, Tuple{Vararg{Int}}}

# Frontier IDs in this checker are L + 16*C + 256*seen, deliberately different
# from the certificate's bit positions. Interned BitSets are never mutated.
mutable struct SemanticContext
    frontiers::Vector{BitSet}
    ids::Dict{BitSet, Int}
    advances::Dict{NTuple{4, Int}, Int}
    steps::Matrix{Vector{Int}}
    closable::Dict{Tuple{Bool, Bool}, BitSet}
end

occupied(column, row) = (column & (1 << (row - 1))) != 0

function stable_center(left, center, right; has_left = true, has_right = true)
    for row in 1:4
        occupied(center, row) || continue
        outside = 0
        row > 1 && !occupied(center, row - 1) && (outside += 1)
        row < 4 && !occupied(center, row + 1) && (outside += 1)
        has_left && !occupied(left, row) && (outside += 1)
        has_right && !occupied(right, row) && (outside += 1)
        outside <= 1 || return false
    end
    return true
end

function seed_center_viable(left, center, right)
    for row in 1:4
        occupied(center, row) || continue
        neighbors = Int(occupied(left, row)) + Int(occupied(right, row))
        row > 1 && occupied(center, row - 1) && (neighbors += 1)
        row < 4 && occupied(center, row + 1) && (neighbors += 1)
        neighbors <= 1 || return false
    end
    return true
end

function SemanticContext()
    steps = Matrix{Vector{Int}}(undef, 3, 512)
    closable = Dict((l, r) => BitSet() for l in (false, true), r in (false, true))

    for index in 0:511
        left, center, seen = mod(index, 16), mod(div(index, 16), 16), index >= 256
        for phase in 0:2
            targets = Int[]
            for right in 0:15
                phase == 0 || stable_center(left, center, right; has_left = phase >= 2) || continue
                push!(targets, center + 16 * right + 256 * Int(seen || right != 0))
            end
            steps[phase + 1, index + 1] = targets
        end
        seen || continue
        for (has_left, has_right) in keys(closable)
            stable_center(left, center, 0; has_left = has_left, has_right = has_right) || continue
            push!(closable[(has_left, has_right)], index)
        end
    end
    return SemanticContext(BitSet[], Dict{BitSet, Int}(), Dict{NTuple{4, Int}, Int}(), steps, closable)
end

function intern!(context, frontiers)
    return get!(context.ids, frontiers) do
        push!(context.frontiers, frontiers)
        length(context.frontiers)
    end
end

function decode_frontiers!(context, encoded)
    words = split(encoded, '.')
    length(words) == 8 || error("a frontier must have eight hexadecimal words")
    frontiers = BitSet()
    for (word_index, word) in enumerate(words)
        length(word) == 16 || error("a frontier word must have sixteen hex digits")
        value = tryparse(UInt64, word; base = 16)
        value === nothing && error("invalid hexadecimal frontier word")
        for bit in 0:63
            (value & (UInt64(1) << bit)) != 0 || continue
            offset = 64 * (word_index - 1) + bit
            seen = isodd(offset)
            pair = div(offset, 2)
            left, center = div(pair, 16), mod(pair, 16)
            push!(frontiers, left + 16 * center + 256 * Int(seen))
        end
    end
    return intern!(context, frontiers)
end

function advance!(context, frontier_id, seeds, phase; hit = 0)
    key = (frontier_id, seeds, phase, hit)
    return get!(context.advances, key) do
        next_frontiers = BitSet()
        for frontier in context.frontiers[frontier_id]
            for target in context.steps[phase + 1, frontier + 1]
                current = mod(div(target, 16), 16)
                (current & seeds) == hit && push!(next_frontiers, target)
            end
        end
        intern!(context, next_frontiers)
    end
end

can_close(context, id, phase; right_exists) =
    !isdisjoint(context.frontiers[id], context.closable[(phase >= 2, right_exists)])

function normalize!(context, obligations, phase; right_exists)
    unresolved = Int[]
    for id in obligations
        can_close(context, id, phase; right_exists = right_exists) && continue
        isempty(context.frontiers[id]) && return nothing
        push!(unresolved, id)
    end
    return Tuple(sort!(unique!(unresolved)))
end

function semantic_transition!(context, state, seeds, phase)
    left, center, avoiding, obligations = state
    phase == 0 || seed_center_viable(left, center, seeds) || return nothing
    new_phase = min(phase + 1, 2)
    next_avoiding = advance!(context, avoiding, seeds, phase)
    can_close(context, next_avoiding, new_phase; right_exists = true) && return nothing

    next_obligations = Int[advance!(context, id, seeds, phase) for id in obligations]
    for row in 1:4
        occupied(seeds, row) || continue
        push!(next_obligations, advance!(context, avoiding, seeds, phase; hit = 1 << (row - 1)))
    end
    normalized = normalize!(context, next_obligations, new_phase; right_exists = true)
    normalized === nothing && return nothing
    return (center, seeds, next_avoiding, normalized)
end

function semantic_accepting(context, state; phase = 2)
    left, center, avoiding, obligations = state
    seed_center_viable(left, center, 0) || return false
    can_close(context, avoiding, phase; right_exists = false) && return false
    return all(id -> can_close(context, id, phase; right_exists = false), obligations)
end

function read_semantic_states!(context, path)
    states = SemanticState[]
    open(path) do io
        readline(io) == "id,prevprev_seed,prev_seed,nohit_bits,obligation_count,obligations" ||
            error("invalid semantic-state header")
        for line in eachline(io)
            fields = split(line, ',')
            length(fields) == 6 || error("invalid semantic-state row")
            id, left, center = parse.(Int, fields[1:3])
            id == length(states) + 1 || error("semantic state IDs must be consecutive")
            0 <= left <= 15 && 0 <= center <= 15 || error("invalid seed-column pattern")
            avoiding = decode_frontiers!(context, fields[4])
            obligations = isempty(fields[6]) ? Int[] :
                [decode_frontiers!(context, value) for value in split(fields[6], ';')]
            count = parse(Int, fields[5])
            length(obligations) == count || error("obligation-count mismatch at state $(id)")
            length(unique(obligations)) == count || error("duplicate obligation at state $(id)")
            push!(states, (left, center, avoiding, Tuple(sort!(obligations))))
        end
    end
    return states
end

function read_semantic_targets(path, compact_edges, num_states)
    targets = zeros(Int, num_states, 16)
    edge_index = 0
    open(path) do io
        readline(io) == "from_state,to_state,seed_column,weight" || error("invalid transition header")
        for line in eachline(io)
            fields = split(line, ',')
            length(fields) == 4 || error("invalid transition row")
            from, to, seeds, weight = parse.(Int, fields)
            1 <= from <= num_states && 1 <= to <= num_states || error("invalid transition endpoint")
            0 <= seeds <= 15 || error("invalid transition column")
            weight == count_ones(seeds) || error("transition has incorrect seed weight")
            targets[from, seeds + 1] == 0 || error("duplicate state/column transition")
            targets[from, seeds + 1] = to
            edge_index += 1
            edge_index <= length(compact_edges) || error("semantic graph has extra edges")
            compact_edges[edge_index] == (from = from, to = to, weight = weight) ||
                error("semantic and arithmetic certificate edge IDs differ at edge $(edge_index)")
        end
    end
    edge_index == length(compact_edges) || error("semantic graph is missing edges")
    return targets
end

function load_semantic_certificate(;
    states_path = joinpath(@__DIR__, "results", "width4_interior_graph_states.csv"),
    transitions_path = joinpath(@__DIR__, "results", "width4_interior_graph_transitions.csv"),
    vertices_path = joinpath(@__DIR__, "results", "width4_boundary_certificate_vertices.csv"),
    edges_path = joinpath(@__DIR__, "results", "width4_boundary_certificate_edges.csv"),
)
    context = SemanticContext()
    states = read_semantic_states!(context, states_path)
    ids = Dict(state => id for (id, state) in enumerate(states))
    length(ids) == length(states) || error("duplicate semantic states")
    accepting, initial_scores = read_width4_certificate_vertices(vertices_path)
    length(accepting) == length(states) || error("semantic and arithmetic vertex counts differ")
    edges = read_width4_certificate_edges(edges_path, length(states))
    targets = read_semantic_targets(transitions_path, edges, length(states))
    return (; context, states, ids, accepting, initial_scores, edges, targets, vertices_path, edges_path)
end

function semantic_warmup_scores!(context)
    initial = (0, 0, intern!(context, BitSet([0])), ())
    scores = Dict{SemanticState, Int}(initial => 0)
    for phase in 0:2
        next_scores = Dict{SemanticState, Int}()
        for (state, score) in scores, seeds in 0:15
            next_state = semantic_transition!(context, state, seeds, phase)
            next_state === nothing && continue
            candidate = score + count_ones(seeds)
            next_scores[next_state] = max(get(next_scores, next_state, -1), candidate)
        end
        scores = next_scores
    end
    return scores
end

function check_semantic_boundaries!(audit)
    warmup = semantic_warmup_scores!(audit.context)
    all(state -> haskey(audit.ids, state), keys(warmup)) || error("a warm-up state is missing")
    for (id, state) in enumerate(audit.states)
        expected = get(warmup, state, CERTIFICATE_NEGATIVE_INFINITY)
        audit.initial_scores[id] == expected || error("warm-up score mismatch at state $(id)")
        audit.accepting[id] == semantic_accepting(audit.context, state) ||
            error("right-boundary acceptance mismatch at state $(id)")
    end
    return length(warmup)
end

function check_semantic_transitions!(audit; state_ids = eachindex(audit.states))
    checked = 0
    for id in state_ids, seeds in 0:15
        next_state = semantic_transition!(audit.context, audit.states[id], seeds, 2)
        expected = next_state === nothing ? 0 : get(audit.ids, next_state, 0)
        next_state === nothing || expected != 0 ||
            error("a legal semantic successor is missing at state $(id), column $(seeds)")
        actual = audit.targets[id, seeds + 1]
        actual == expected || error("semantic transition mismatch at state $(id), column $(seeds)")
        checked += 1
    end
    return checked
end

function verify_loaded_semantic_certificate!(audit; progress = nothing)
    progress === nothing || println(progress, "semantic states loaded = ", length(audit.states))
    warmup_count = check_semantic_boundaries!(audit)
    progress === nothing || println(progress, "warm-up states verified = ", warmup_count)
    checked = check_semantic_transitions!(audit)
    reached = forward_reachable_vertices(length(audit.states), audit.edges, audit.initial_scores)
    all(reached) || error("semantic graph includes unreachable states")
    arithmetic = check_width4_boundary_certificate(audit.vertices_path, audit.edges_path)
    arithmetic.values[4] == 5 || error("exceptional n=4 value mismatch")
    return (
        verified = true,
        states = length(audit.states),
        edges = length(audit.edges),
        column_choices_checked = checked,
        warmup_states = warmup_count,
        frontier_sets = length(audit.context.frontiers),
        accepting_states = count(audit.accepting),
        arithmetic = arithmetic,
    )
end

function check_width4_semantic_certificate(; progress = nothing, paths...)
    audit = load_semantic_certificate(; paths...)
    return verify_loaded_semantic_certificate!(audit; progress = progress)
end

function print_semantic_report(io, result)
    println(io, "verified = ", result.verified)
    println(io, "states = ", result.states)
    println(io, "edges = ", result.edges)
    println(io, "column_choices_checked = ", result.column_choices_checked)
    println(io, "rejected_column_choices = ", result.column_choices_checked - result.edges)
    println(io, "warmup_states = ", result.warmup_states)
    println(io, "accepting_states = ", result.accepting_states)
    println(io, "boundary_core_states = ", result.arithmetic.core_states)
    println(io, "boundary_core_edges = ", result.arithmetic.core_edges)
    println(io, "E_4_4 = ", result.arithmetic.values[4])
    println(io, "score_vector_recurrence = v_22 = v_19 + 2")
    println(io, "formula_verified_for_n = 5..22, and all n >= 5 by recurrence")
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    result = Width4SemanticCertificate.check_width4_semantic_certificate(; progress = stdout)
    Width4SemanticCertificate.print_semantic_report(stdout, result)
    if !isempty(ARGS)
        open(ARGS[1], "w") do io
            Width4SemanticCertificate.print_semantic_report(io, result)
        end
    end
end
