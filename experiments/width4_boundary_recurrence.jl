if !@isdefined(width4_interior_transition_graph)
    include("width4_transition_export.jl")
end

if !@isdefined(width4_is_accepting_state)
    include("width4_graph_acceptance.jl")
end

const WIDTH4_NEGATIVE_INFINITY = typemin(Int) ÷ 4

function width4_boundary_core(graph)
    accepting = [width4_is_accepting_state(state, max(graph.warmup_cols, 3)) for state in graph.states]
    reverse_adjacency = [Int[] for _ in graph.states]

    for edge in graph.edges
        push!(reverse_adjacency[edge.to], edge.from)
    end

    coaccessible = copy(accepting)
    queue = findall(accepting)
    cursor = 1

    while cursor <= length(queue)
        vertex = queue[cursor]
        cursor += 1

        for predecessor in reverse_adjacency[vertex]
            if !coaccessible[predecessor]
                coaccessible[predecessor] = true
                push!(queue, predecessor)
            end
        end
    end

    return (
        accepting = accepting,
        coaccessible = coaccessible,
        accepting_count = count(accepting),
        state_count = count(coaccessible),
        edge_count = count(edge -> coaccessible[edge.from] && coaccessible[edge.to], graph.edges),
    )
end

function width4_warmup_scores(warmup_cols)
    initial_state = (0, 0, initial_stable_bits(), Tuple(Width4StableBits[]))
    scores = Dict{Width4InteriorState, Int}(initial_state => 0)

    for col in 1:warmup_cols
        next_scores = Dict{Width4InteriorState, Int}()

        for (state, score) in scores
            for seed_column in 0:15
                next_state = advance_width4_interior_state(state, seed_column, col; right_exists = true)
                next_state === nothing && continue
                candidate = score + column_seed_count(seed_column)
                next_scores[next_state] = max(get(next_scores, next_state, WIDTH4_NEGATIVE_INFINITY), candidate)
            end
        end

        scores = next_scores
    end

    return scores
end

function width4_advance_core_scores(scores, graph, core)
    next_scores = fill(WIDTH4_NEGATIVE_INFINITY, length(scores))

    for edge in graph.edges
        core.coaccessible[edge.from] && core.coaccessible[edge.to] || continue
        scores[edge.from] == WIDTH4_NEGATIVE_INFINITY && continue
        candidate = scores[edge.from] + edge.weight
        next_scores[edge.to] = max(next_scores[edge.to], candidate)
    end

    return next_scores
end

function width4_scores_shift_equal(left, right, core, gain)
    for vertex in eachindex(left)
        core.coaccessible[vertex] || continue

        if left[vertex] == WIDTH4_NEGATIVE_INFINITY
            right[vertex] == WIDTH4_NEGATIVE_INFINITY || return false
        elseif right[vertex] != left[vertex] + gain
            return false
        end
    end

    return true
end

function width4_best_accepting_score(scores, core)
    best = WIDTH4_NEGATIVE_INFINITY

    for vertex in eachindex(scores)
        core.accepting[vertex] || continue
        best = max(best, scores[vertex])
    end

    return best == WIDTH4_NEGATIVE_INFINITY ? nothing : best
end

function width4_boundary_recurrence_certificate(;
    warmup_cols = 3,
    max_states = 250_000,
    max_cols = 100,
    period = 3,
    gain = 2,
)
    graph = width4_interior_transition_graph(; warmup_cols = warmup_cols, max_states = max_states)
    graph.truncated && error("transition graph was truncated")
    core = width4_boundary_core(graph)
    ids = Dict(state => id for (id, state) in enumerate(graph.states))
    scores = fill(WIDTH4_NEGATIVE_INFINITY, length(graph.states))

    for (state, score) in width4_warmup_scores(warmup_cols)
        id = ids[state]
        core.coaccessible[id] || continue
        scores[id] = max(scores[id], score)
    end

    history = Dict{Int, Vector{Int}}()
    values = Dict{Int, Int}()
    recurrence_start = nothing
    recurrence_end = nothing

    for col in warmup_cols:max_cols
        history[col] = scores
        best = width4_best_accepting_score(scores, core)
        best === nothing || (values[col] = best)

        earlier_col = col - period
        if haskey(history, earlier_col) && width4_scores_shift_equal(history[earlier_col], scores, core, gain)
            recurrence_start = earlier_col
            recurrence_end = col
            break
        end

        scores = width4_advance_core_scores(scores, graph, core)
    end

    recurrence_start === nothing && error("no score-vector recurrence found through column $(max_cols)")

    return (
        period = period,
        gain = gain,
        recurrence_start = recurrence_start,
        recurrence_end = recurrence_end,
        values = values,
        graph_states = length(graph.states),
        graph_edges = length(graph.edges),
        accepting_states = core.accepting_count,
        core_states = core.state_count,
        core_edges = core.edge_count,
    )
end

function print_width4_boundary_recurrence_certificate(certificate, io = stdout)
    println(io, "graph_states = ", certificate.graph_states)
    println(io, "graph_edges = ", certificate.graph_edges)
    println(io, "right_accepting_states = ", certificate.accepting_states)
    println(io, "boundary_core_states = ", certificate.core_states)
    println(io, "boundary_core_edges = ", certificate.core_edges)
    println(io, "score_vector_period = ", certificate.period)
    println(io, "score_vector_gain = ", certificate.gain)
    println(io, "recurrence_start = ", certificate.recurrence_start)
    println(io, "recurrence_verified_at = ", certificate.recurrence_end)
    println(io, "accepted_values = ", join(("$(n):$(certificate.values[n])" for n in sort(collect(keys(certificate.values)))), ","))
end

if abspath(PROGRAM_FILE) == @__FILE__
    certificate = width4_boundary_recurrence_certificate()
    print_width4_boundary_recurrence_certificate(certificate)

    if !isempty(ARGS)
        open(ARGS[1], "w") do io
            print_width4_boundary_recurrence_certificate(certificate, io)
        end
    end
end
