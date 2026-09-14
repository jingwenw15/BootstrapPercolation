if !@isdefined(width4_stable_witness_summary_bits)
    include("width4_stable_sets.jl")
end

function seed_hit_bit_for_column(cols, col, stable_column, seed_column)
    seed_hits = stable_column & seed_column
    seed_hits == 0 && return UInt64(0)
    count_ones(UInt64(seed_hits)) == 1 || return nothing

    row = trailing_zeros(seed_hits) + 1
    return UInt64(1) << bit_index(4, cols, row, col)
end

function advance_width4_witness_states(states, cols, col, seed_column)
    next_states = Dict{UInt64, Width4StableBits}()

    for (hit_seed, bits) in states
        foreach_stable_bit_index(bits) do index
            prevprev, prev, seen_nonempty = stable_state_tuple(index)

            for stable_column in 0:15
                current_hit = seed_hit_bit_for_column(cols, col, stable_column, seed_column)
                if current_hit !== nothing && !(current_hit != 0 && hit_seed != 0)
                    if !(col >= 2 && !finalized_column_is_stable(4, prevprev, prev, stable_column; left_exists = col >= 3))
                        next_hit = hit_seed | current_hit
                        next_index = stable_state_index(prev, stable_column, seen_nonempty || stable_column != 0)
                        next_bits = get(next_states, next_hit, ntuple(_ -> UInt64(0), 8))
                        next_states[next_hit] = stable_bits_add(next_bits, next_index)
                    end
                end
            end
        end
    end

    return next_states
end

function active_witness_seed_mask(states)
    witnessed = UInt64(0)

    for hit_seed in keys(states)
        witnessed |= hit_seed
    end

    return witnessed
end

function accepting_witness_summary(states, cols)
    has_zero_seed_obstruction = false
    witnessed_seeds = UInt64(0)

    for (hit_seed, bits) in states
        foreach_stable_bit_index(bits) do index
            prevprev, prev, seen_nonempty = stable_state_tuple(index)
            if finalized_column_is_stable(4, prevprev, prev, 0; left_exists = cols >= 2, right_exists = false)
                if hit_seed == 0
                    seen_nonempty && (has_zero_seed_obstruction = true)
                else
                    witnessed_seeds |= hit_seed
                end
            end
        end
    end

    return (
        has_zero_seed_obstruction = has_zero_seed_obstruction,
        witnessed_seeds = witnessed_seeds,
    )
end

function foreach_width4_witness_pruned_candidate(callback, cols, size)
    patterns = collect(0:15)
    initial_states = Dict{UInt64, Width4StableBits}(UInt64(0) => initial_stable_bits())

    function extend(col, prevprev_seed, prev_seed, used, mask, states)
        if col > cols
            used == size || return
            finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, 0) || return

            summary = accepting_witness_summary(states, cols)
            if !summary.has_zero_seed_obstruction && summary.witnessed_seeds == mask
                callback(mask)
            end

            return
        end

        for seed_column in patterns
            new_used = used + column_seed_count(seed_column)
            new_used <= size || continue

            if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
                continue
            end

            new_mask = append_column_mask(4, cols, mask, col, seed_column)
            new_states = advance_width4_witness_states(states, cols, col, seed_column)

            # Once a seed's column has been processed, any one-seed witness for
            # that seed must already have hit it. If no active witness state has
            # done so, no future columns can repair the branch.
            (new_mask & ~active_witness_seed_mask(new_states)) == 0 || continue

            extend(col + 1, prev_seed, seed_column, new_used, new_mask, new_states)
        end
    end

    extend(1, 0, 0, 0, UInt64(0), initial_states)
    return nothing
end

function width4_find_minimal_by_witness_pruning(cols, size; store = true, canonical = true)
    matches = store ? UInt64[] : nothing
    generated_minimal = 0
    checked_representatives = 0
    skipped_noncanonical = 0
    raw_matches = 0
    class_matches = 0

    foreach_width4_witness_pruned_candidate(cols, size) do mask
        generated_minimal += 1

        if canonical && mask != fast_canonical_rectangle_mask(4, cols, mask)
            skipped_noncanonical += 1
            return
        end

        checked_representatives += 1
        class_matches += 1
        raw_matches += canonical ? fast_rectangle_orbit_size(4, cols, mask) : 1
        store && push!(matches, mask)
    end

    return (
        cols = cols,
        size = size,
        generated_minimal = generated_minimal,
        checked_representatives = checked_representatives,
        skipped_noncanonical = skipped_noncanonical,
        raw_maximizers = raw_matches,
        symmetry_classes = class_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function stable_bits_is_empty(bits::Width4StableBits)
    return all(word == 0 for word in bits)
end

function stable_bits_can_close(bits::Width4StableBits, col; right_exists)
    for word_index in 1:8
        word = bits[word_index]
        base = (word_index - 1) * 64

        while word != 0
            bit = word & -word
            index = base + trailing_zeros(bit) + 1
            prevprev, prev, seen_nonempty = stable_state_tuple(index)

            if seen_nonempty && finalized_column_is_stable(4, prevprev, prev, 0; left_exists = col >= 2, right_exists = right_exists)
                return true
            end

            word &= word - UInt64(1)
        end
    end

    return false
end

function advance_width4_hit_bits(nohit_bits::Width4StableBits, cols, col, seed_column, hit_row)
    hit_pattern = 1 << (hit_row - 1)
    next_bits = ntuple(_ -> UInt64(0), 8)

    foreach_stable_bit_index(nohit_bits) do index
        prevprev, prev, seen_nonempty = stable_state_tuple(index)

        for stable_column in 0:15
            (stable_column & seed_column) == hit_pattern || continue

            if !(col >= 2 && !finalized_column_is_stable(4, prevprev, prev, stable_column; left_exists = col >= 3))
                next_index = stable_state_index(prev, stable_column, seen_nonempty || stable_column != 0)
                next_bits = stable_bits_add(next_bits, next_index)
            end
        end
    end

    return next_bits
end

function normalize_obligations(obligations, col, cols)
    normalized = Width4StableBits[]
    right_exists = col < cols

    for bits in obligations
        stable_bits_can_close(bits, col; right_exists = right_exists) && continue
        stable_bits_is_empty(bits) && return nothing
        push!(normalized, bits)
    end

    return Tuple(sort(unique(normalized)))
end

function add_current_seed_obligations(obligations, nohit_before, cols, col, seed_column)
    result = Width4StableBits[obligations...]

    for row in 1:4
        column_bit(seed_column, row) || continue
        bits = advance_width4_hit_bits(nohit_before, cols, col, seed_column, row)
        push!(result, bits)
    end

    return result
end

function advance_obligations(obligations, seed_column, col)
    return [advance_stable_bits(bits, seed_column, col) for bits in obligations]
end

function width4_count_minimal_by_merged_state(cols, size)
    patterns = collect(0:15)
    initial_nohit = initial_stable_bits()
    initial_obligations = Tuple(Width4StableBits[])
    states = Dict{Tuple{Int, Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}, Int}()
    states[(0, 0, 0, initial_nohit, initial_obligations)] = 1
    states_by_column = Int[length(states)]

    for col in 1:cols
        next_states = Dict{Tuple{Int, Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}, Int}()

        for ((prevprev_seed, prev_seed, used, nohit_bits, obligations), count) in states
            for seed_column in patterns
                new_used = used + column_seed_count(seed_column)
                new_used <= size || continue

                if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
                    continue
                end

                next_nohit = advance_stable_bits(nohit_bits, seed_column, col)
                stable_bits_can_close(next_nohit, col; right_exists = col < cols) && continue

                next_obligations = advance_obligations(obligations, seed_column, col)
                next_obligations = add_current_seed_obligations(next_obligations, nohit_bits, cols, col, seed_column)
                normalized = normalize_obligations(next_obligations, col, cols)
                normalized === nothing && continue

                key = (prev_seed, seed_column, new_used, next_nohit, normalized)
                next_states[key] = get(next_states, key, 0) + count
            end
        end

        states = next_states
        push!(states_by_column, length(states))
    end

    total = 0

    for ((prevprev_seed, prev_seed, used, nohit_bits, obligations), count) in states
        used == size || continue
        finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, 0) || continue
        stable_bits_can_close(nohit_bits, cols; right_exists = false) && continue

        normalized = normalize_obligations(obligations, cols, cols)
        normalized === nothing && continue
        isempty(normalized) || continue

        total += count
    end

    return (
        cols = cols,
        size = size,
        raw_minimal_percolating = total,
        states_by_column = states_by_column,
        final_states = length(states),
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    cols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 9
    size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : cols
    result = width4_count_minimal_by_merged_state(cols, size)

    println("grid = 4 x ", cols)
    println("size = ", size)
    println("raw minimal percolating = ", result.raw_minimal_percolating)
    println("states by column = ", result.states_by_column)
end
