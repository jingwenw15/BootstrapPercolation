if !@isdefined(fast_is_minimal_percolating)
    include("fast_exact.jl")
end

# This is a deliberately direct reference implementation of the finite-state
# model. It favors a literal representation of sets over the packed width-four
# bitsets used by the main computation.

const FixedStableFrontier = Tuple{Int, Int, Bool}
const FixedStableFrontierSet = Tuple{Vararg{FixedStableFrontier}}

function fixed_width_column_bit(column, row)
    return (column & (1 << (row - 1))) != 0
end

function fixed_width_finalized_stable(
    height,
    left,
    center,
    right;
    left_exists = true,
    right_exists = true,
)
    for row in 1:height
        fixed_width_column_bit(center, row) || continue
        outside = 0

        row > 1 && !fixed_width_column_bit(center, row - 1) && (outside += 1)
        row < height && !fixed_width_column_bit(center, row + 1) && (outside += 1)
        left_exists && !fixed_width_column_bit(left, row) && (outside += 1)
        right_exists && !fixed_width_column_bit(right, row) && (outside += 1)

        outside <= 1 || return false
    end

    return true
end

function fixed_width_seed_column_viable(height, left, center, right)
    for row in 1:height
        fixed_width_column_bit(center, row) || continue
        infected_neighbors = 0

        row > 1 && fixed_width_column_bit(center, row - 1) && (infected_neighbors += 1)
        row < height && fixed_width_column_bit(center, row + 1) && (infected_neighbors += 1)
        fixed_width_column_bit(left, row) && (infected_neighbors += 1)
        fixed_width_column_bit(right, row) && (infected_neighbors += 1)

        infected_neighbors <= 1 || return false
    end

    return true
end

function canonical_fixed_frontiers(frontiers)
    return Tuple(sort!(unique!(collect(frontiers))))
end

function fixed_width_advance_frontiers(frontiers, height, seed_column, col; hit = 0)
    next_frontiers = FixedStableFrontier[]
    last_column = (1 << height) - 1

    for (left, center, seen_nonempty) in frontiers
        for right in 0:last_column
            intersection = right & seed_column
            intersection == hit || continue

            if col >= 2 && !fixed_width_finalized_stable(
                height,
                left,
                center,
                right;
                left_exists = col >= 3,
            )
                continue
            end

            push!(next_frontiers, (center, right, seen_nonempty || right != 0))
        end
    end

    return canonical_fixed_frontiers(next_frontiers)
end

function fixed_width_can_close(frontiers, height, col; right_exists)
    for (left, center, seen_nonempty) in frontiers
        seen_nonempty || continue

        if fixed_width_finalized_stable(
            height,
            left,
            center,
            0;
            left_exists = col >= 2,
            right_exists = right_exists,
        )
            return true
        end
    end

    return false
end

function normalize_fixed_obligations(obligations, height, col; right_exists)
    unresolved = FixedStableFrontierSet[]

    for frontiers in obligations
        fixed_width_can_close(frontiers, height, col; right_exists = right_exists) && continue
        isempty(frontiers) && return nothing
        push!(unresolved, frontiers)
    end

    return Tuple(sort!(unique!(unresolved)))
end

function initial_fixed_width_state()
    initial_frontiers = ((0, 0, false),)
    return (0, 0, initial_frontiers, ())
end

function fixed_width_transition(state, height, seed_column, col; right_exists)
    previous_seed, current_seed, avoiding, obligations = state

    if col >= 2 && !fixed_width_seed_column_viable(height, previous_seed, current_seed, seed_column)
        return nothing
    end

    next_avoiding = fixed_width_advance_frontiers(avoiding, height, seed_column, col)
    fixed_width_can_close(next_avoiding, height, col; right_exists = right_exists) && return nothing

    next_obligations = FixedStableFrontierSet[]
    for frontiers in obligations
        push!(next_obligations, fixed_width_advance_frontiers(frontiers, height, seed_column, col))
    end

    for row in 1:height
        hit = 1 << (row - 1)
        (seed_column & hit) == 0 && continue
        push!(next_obligations, fixed_width_advance_frontiers(avoiding, height, seed_column, col; hit = hit))
    end

    normalized = normalize_fixed_obligations(next_obligations, height, col; right_exists = right_exists)
    normalized === nothing && return nothing
    return (current_seed, seed_column, next_avoiding, normalized)
end

function fixed_width_accepting(state, height, cols)
    previous_seed, current_seed, avoiding, obligations = state
    fixed_width_seed_column_viable(height, previous_seed, current_seed, 0) || return false
    fixed_width_can_close(avoiding, height, cols; right_exists = false) && return false

    normalized = normalize_fixed_obligations(obligations, height, cols; right_exists = false)
    return normalized !== nothing && isempty(normalized)
end

function fixed_width_word_is_accepted(height, seed_columns; stationary = true)
    state = initial_fixed_width_state()
    cols = length(seed_columns)

    for (col, seed_column) in enumerate(seed_columns)
        0 <= seed_column < (1 << height) || throw(ArgumentError("invalid seed column"))
        right_exists = stationary || col < cols
        state = fixed_width_transition(state, height, seed_column, col; right_exists = right_exists)
        state === nothing && return false
    end

    return fixed_width_accepting(state, height, cols)
end

function merge_fixed_width_value!(states, state, weight, best_count, total_count)
    if !haskey(states, state)
        states[state] = (weight = weight, best_count = best_count, total_count = total_count)
        return
    end

    current = states[state]
    new_total = current.total_count + total_count

    if weight > current.weight
        states[state] = (weight = weight, best_count = best_count, total_count = new_total)
    elseif weight == current.weight
        states[state] = (
            weight = weight,
            best_count = current.best_count + best_count,
            total_count = new_total,
        )
    else
        states[state] = (
            weight = current.weight,
            best_count = current.best_count,
            total_count = new_total,
        )
    end
end

function fixed_width_reference_value(height, cols; stationary = true)
    height >= 1 || throw(ArgumentError("height must be positive"))
    cols >= 1 || throw(ArgumentError("cols must be positive"))
    states = Dict{Any, NamedTuple}(
        initial_fixed_width_state() => (weight = 0, best_count = BigInt(1), total_count = BigInt(1)),
    )

    for col in 1:cols
        next_states = Dict{Any, NamedTuple}()

        for (state, value) in states
            for seed_column in 0:((1 << height) - 1)
                right_exists = stationary || col < cols
                next_state = fixed_width_transition(state, height, seed_column, col; right_exists = right_exists)
                next_state === nothing && continue
                merge_fixed_width_value!(
                    next_states,
                    next_state,
                    value.weight + count_ones(UInt(seed_column)),
                    value.best_count,
                    value.total_count,
                )
            end
        end

        states = next_states
    end

    maximum_size = nothing
    maximizing_count = BigInt(0)
    minimal_count = BigInt(0)

    for (state, value) in states
        fixed_width_accepting(state, height, cols) || continue
        minimal_count += value.total_count

        if maximum_size === nothing || value.weight > maximum_size
            maximum_size = value.weight
            maximizing_count = value.best_count
        elseif value.weight == maximum_size
            maximizing_count += value.best_count
        end
    end

    return (
        maximum_size = maximum_size,
        maximizing_count = maximizing_count,
        minimal_count = minimal_count,
        final_states = length(states),
    )
end

function fixed_width_columns_from_mask(height, cols, mask)
    return [
        sum(
            ((mask >> bit_index(height, cols, row, col)) & UInt64(1)) << (row - 1)
            for row in 1:height
        ) |> Int
        for col in 1:cols
    ]
end

function fixed_width_brute_summary(height, cols)
    total = height * cols
    total <= 63 || throw(ArgumentError("brute summary supports at most 63 cells"))
    neighbors = neighbor_masks(height, cols)
    maximum_size = nothing
    maximizing_count = 0
    minimal_count = 0

    for mask in UInt64(0):((UInt64(1) << total) - UInt64(1))
        fast_is_minimal_percolating(height, cols, mask, neighbors) || continue
        minimal_count += 1
        size = count_ones(mask)

        if maximum_size === nothing || size > maximum_size
            maximum_size = size
            maximizing_count = 1
        elseif size == maximum_size
            maximizing_count += 1
        end
    end

    return (
        maximum_size = maximum_size,
        maximizing_count = maximizing_count,
        minimal_count = minimal_count,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    height = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 4
    cols = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 3
    stationary = length(ARGS) >= 3 ? parse(Bool, ARGS[3]) : true
    reference = fixed_width_reference_value(height, cols; stationary = stationary)
    brute = fixed_width_brute_summary(height, cols)

    println("grid = ", height, " x ", cols)
    println("stationary = ", stationary)
    println("reference = ", reference)
    println("brute = ", brute)
    reference.maximum_size == brute.maximum_size || error("maximum-size mismatch")
    reference.maximizing_count == brute.maximizing_count || error("maximizer-count mismatch")
    reference.minimal_count == brute.minimal_count || error("minimal-count mismatch")
    println("verified = true")
end
