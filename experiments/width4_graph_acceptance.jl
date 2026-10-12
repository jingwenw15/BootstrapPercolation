if !@isdefined(width4_count_minimal_by_merged_state)
    include("width4_minimality_dp.jl")
end

const Width4AcceptanceState = Tuple{Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}

function normalize_acceptance_obligations(obligations, col; right_exists)
    normalized = Width4StableBits[]

    for bits in obligations
        stable_bits_can_close(bits, col; right_exists = right_exists) && continue
        stable_bits_is_empty(bits) && return nothing
        push!(normalized, bits)
    end

    return Tuple(sort(unique(normalized)))
end

function width4_acceptance_transition(state::Width4AcceptanceState, seed_column, col; right_exists)
    prevprev_seed, prev_seed, nohit_bits, obligations = state

    if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
        return nothing
    end

    next_nohit = advance_stable_bits(nohit_bits, seed_column, col)
    stable_bits_can_close(next_nohit, col; right_exists = right_exists) && return nothing

    next_obligations = advance_obligations(obligations, seed_column, col)
    next_obligations = add_current_seed_obligations(next_obligations, nohit_bits, max(col + 1, 4), col, seed_column)
    normalized = normalize_acceptance_obligations(next_obligations, col; right_exists = right_exists)
    normalized === nothing && return nothing

    return (prev_seed, seed_column, next_nohit, normalized)
end

function width4_is_accepting_state(state::Width4AcceptanceState, cols)
    prevprev_seed, prev_seed, nohit_bits, obligations = state
    finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, 0) || return false
    stable_bits_can_close(nohit_bits, cols; right_exists = false) && return false

    normalized = normalize_acceptance_obligations(obligations, cols; right_exists = false)
    normalized === nothing && return false
    return isempty(normalized)
end

function merge_best_state!(states, state::Width4AcceptanceState, weight, count)
    if !haskey(states, state)
        states[state] = (weight = weight, count = count)
        return
    end

    current = states[state]

    if weight > current.weight
        states[state] = (weight = weight, count = count)
    elseif weight == current.weight
        states[state] = (weight = weight, count = current.count + count)
    end
end

function width4_graph_acceptance_value(cols)
    initial_state = (0, 0, initial_stable_bits(), Tuple(Width4StableBits[]))
    states = Dict{Width4AcceptanceState, NamedTuple{(:weight, :count), Tuple{Int, Int}}}()
    states[initial_state] = (weight = 0, count = 1)
    states_by_column = Int[length(states)]

    for col in 1:cols
        next_states = Dict{Width4AcceptanceState, NamedTuple{(:weight, :count), Tuple{Int, Int}}}()

        for (state, value) in states
            for seed_column in 0:15
                next_state = width4_acceptance_transition(state, seed_column, col; right_exists = col < cols)
                next_state === nothing && continue

                merge_best_state!(
                    next_states,
                    next_state,
                    value.weight + column_seed_count(seed_column),
                    value.count,
                )
            end
        end

        states = next_states
        push!(states_by_column, length(states))
    end

    best = typemin(Int)
    count = 0
    accepting_states = 0

    for (state, value) in states
        width4_is_accepting_state(state, cols) || continue
        accepting_states += 1

        if value.weight > best
            best = value.weight
            count = value.count
        elseif value.weight == best
            count += value.count
        end
    end

    return (
        cols = cols,
        maximum_size = best == typemin(Int) ? nothing : best,
        raw_maximizers = count,
        accepting_states = accepting_states,
        states_by_column = states_by_column,
        final_states = length(states),
    )
end

function width4_graph_acceptance_sequence(last_col; first_col = 1)
    1 <= first_col <= last_col || throw(ArgumentError("require 1 <= first_col <= last_col"))

    initial_state = (0, 0, initial_stable_bits(), Tuple(Width4StableBits[]))
    states = Dict{Width4AcceptanceState, NamedTuple{(:weight, :count), Tuple{Int, BigInt}}}()
    states[initial_state] = (weight = 0, count = BigInt(1))
    rows = NamedTuple[]
    maximum_states = length(states)

    for col in 1:last_col
        next_states = Dict{Width4AcceptanceState, NamedTuple{(:weight, :count), Tuple{Int, BigInt}}}()

        for (state, value) in states
            for seed_column in 0:15
                next_state = width4_acceptance_transition(state, seed_column, col; right_exists = true)
                next_state === nothing && continue

                merge_best_state!(
                    next_states,
                    next_state,
                    value.weight + column_seed_count(seed_column),
                    value.count,
                )
            end
        end

        states = next_states
        maximum_states = max(maximum_states, length(states))
        col < first_col && continue

        best = typemin(Int)
        count = BigInt(0)
        accepting_states = 0

        for (state, value) in states
            width4_is_accepting_state(state, col) || continue
            accepting_states += 1

            if value.weight > best
                best = value.weight
                count = value.count
            elseif value.weight == best
                count += value.count
            end
        end

        push!(
            rows,
            (
                cols = col,
                maximum_size = best == typemin(Int) ? nothing : best,
                raw_maximizers = count,
                accepting_states = accepting_states,
                states = length(states),
                max_states = maximum_states,
            ),
        )
    end

    return rows
end

function width4_graph_acceptance_table(first_col, last_col)
    return [width4_graph_acceptance_value(cols) for cols in first_col:last_col]
end

function print_width4_graph_acceptance_table(rows)
    println("n,E_4n,raw_maximizers,accepting_states,max_states")

    for row in rows
        println(
            row.cols,
            ",",
            row.maximum_size,
            ",",
            row.raw_maximizers,
            ",",
            row.accepting_states,
            ",",
            maximum(row.states_by_column),
        )
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    first_col = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 4
    last_col = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 12

    print_width4_graph_acceptance_table(width4_graph_acceptance_table(first_col, last_col))
end
