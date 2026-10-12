if !@isdefined(width4_count_minimal_by_merged_state)
    include("width4_minimality_dp.jl")
end

const Width4InteriorState = Tuple{Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}

function stable_bits_key(bits::Width4StableBits)
    return join((string(word; base = 16, pad = 16) for word in bits), ".")
end

function obligation_key(obligations)
    isempty(obligations) && return ""
    return join((stable_bits_key(bits) for bits in obligations), ";")
end

function interior_state_key(state::Width4InteriorState)
    prevprev_seed, prev_seed, nohit_bits, obligations = state
    return join((prevprev_seed, prev_seed, stable_bits_key(nohit_bits), obligation_key(obligations)), "|")
end

function normalize_obligations_with_boundary(obligations, col; right_exists)
    normalized = Width4StableBits[]

    for bits in obligations
        stable_bits_can_close(bits, col; right_exists = right_exists) && continue
        stable_bits_is_empty(bits) && return nothing
        push!(normalized, bits)
    end

    return Tuple(sort(unique(normalized)))
end

function advance_width4_interior_state(state::Width4InteriorState, seed_column, col; right_exists)
    prevprev_seed, prev_seed, nohit_bits, obligations = state

    if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
        return nothing
    end

    next_nohit = advance_stable_bits(nohit_bits, seed_column, col)
    stable_bits_can_close(next_nohit, col; right_exists = right_exists) && return nothing

    next_obligations = advance_obligations(obligations, seed_column, col)
    next_obligations = add_current_seed_obligations(next_obligations, nohit_bits, max(col + 1, 4), col, seed_column)
    normalized = normalize_obligations_with_boundary(next_obligations, col; right_exists = right_exists)
    normalized === nothing && return nothing

    return (prev_seed, seed_column, next_nohit, normalized)
end

function width4_left_boundary_states(warmup_cols)
    states = Set{Width4InteriorState}()
    push!(states, (0, 0, initial_stable_bits(), Tuple(Width4StableBits[])))

    for col in 1:warmup_cols
        next_states = Set{Width4InteriorState}()

        for state in states
            for seed_column in 0:15
                next_state = advance_width4_interior_state(state, seed_column, col; right_exists = true)
                next_state === nothing && continue
                push!(next_states, next_state)
            end
        end

        states = next_states
    end

    return states
end

function ensure_state_id!(ids, states, state::Width4InteriorState)
    key = interior_state_key(state)

    if haskey(ids, key)
        return ids[key]
    end

    id = length(states) + 1
    ids[key] = id
    push!(states, state)
    return id
end

function width4_interior_transition_graph(; warmup_cols = 3, max_states = 250_000)
    ids = Dict{String, Int}()
    states = Width4InteriorState[]
    edges = NamedTuple[]
    queue = Int[]

    for state in width4_left_boundary_states(warmup_cols)
        id = ensure_state_id!(ids, states, state)
        push!(queue, id)
    end

    cursor = 1

    while cursor <= length(queue)
        from_id = queue[cursor]
        cursor += 1
        state = states[from_id]

        for seed_column in 0:15
            next_state = advance_width4_interior_state(state, seed_column, 3; right_exists = true)
            next_state === nothing && continue

            old_count = length(states)
            to_id = ensure_state_id!(ids, states, next_state)

            if length(states) > old_count
                if length(states) > max_states
                    return (
                        states = states,
                        edges = edges,
                        truncated = true,
                        max_states = max_states,
                        warmup_cols = warmup_cols,
                    )
                end

                push!(queue, to_id)
            end

            push!(
                edges,
                (
                    from = from_id,
                    to = to_id,
                    seed_column = seed_column,
                    weight = column_seed_count(seed_column),
                ),
            )
        end
    end

    return (
        states = states,
        edges = edges,
        truncated = false,
        max_states = max_states,
        warmup_cols = warmup_cols,
    )
end

function write_width4_transition_graph(prefix; warmup_cols = 3, max_states = 250_000)
    graph = width4_interior_transition_graph(; warmup_cols = warmup_cols, max_states = max_states)
    states_path = prefix * "_states.csv"
    transitions_path = prefix * "_transitions.csv"
    summary_path = prefix * "_summary.txt"

    open(states_path, "w") do io
        println(io, "id,prevprev_seed,prev_seed,nohit_bits,obligation_count,obligations")

        for (id, state) in enumerate(graph.states)
            prevprev_seed, prev_seed, nohit_bits, obligations = state
            println(
                io,
                id,
                ",",
                prevprev_seed,
                ",",
                prev_seed,
                ",",
                stable_bits_key(nohit_bits),
                ",",
                length(obligations),
                ",",
                obligation_key(obligations),
            )
        end
    end

    open(transitions_path, "w") do io
        println(io, "from_state,to_state,seed_column,weight")

        for edge in graph.edges
            println(io, edge.from, ",", edge.to, ",", edge.seed_column, ",", edge.weight)
        end
    end

    open(summary_path, "w") do io
        println(io, "warmup_cols = ", graph.warmup_cols)
        println(io, "states = ", length(graph.states))
        println(io, "transitions = ", length(graph.edges))
        println(io, "truncated = ", graph.truncated)
        println(io, "max_states = ", graph.max_states)
        println(io, "states_csv = ", states_path)
        println(io, "transitions_csv = ", transitions_path)
    end

    return graph
end

if abspath(PROGRAM_FILE) == @__FILE__
    prefix = length(ARGS) >= 1 ? ARGS[1] : "experiments/results/width4_interior_graph"
    max_states = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 250_000
    warmup_cols = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 3
    graph = write_width4_transition_graph(prefix; warmup_cols = warmup_cols, max_states = max_states)

    println("states = ", length(graph.states))
    println("transitions = ", length(graph.edges))
    println("truncated = ", graph.truncated)
end
