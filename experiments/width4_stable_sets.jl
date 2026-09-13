if !@isdefined(fast_is_minimal_percolating)
    include("fast_exact.jl")
end

if !@isdefined(finalized_column_has_no_forced_seed)
    include("width4_transfer.jl")
end

function width4_column(mask, cols, col)
    pattern = 0

    for row in 1:4
        bit = UInt64(1) << bit_index(4, cols, row, col)
        if (mask & bit) != 0
            pattern |= 1 << (row - 1)
        end
    end

    return pattern
end

function stable_column_cell_degree(rows, left, center, right, row; left_exists = true, right_exists = true)
    degree = 0
    inside = 0

    if row > 1
        degree += 1
        column_bit(center, row - 1) && (inside += 1)
    end

    if row < rows
        degree += 1
        column_bit(center, row + 1) && (inside += 1)
    end

    if left_exists
        degree += 1
        column_bit(left, row) && (inside += 1)
    end

    if right_exists
        degree += 1
        column_bit(right, row) && (inside += 1)
    end

    return degree, inside
end

function finalized_column_is_stable(rows, left, center, right; left_exists = true, right_exists = true)
    for row in 1:rows
        column_bit(center, row) || continue

        degree, inside = stable_column_cell_degree(
            rows,
            left,
            center,
            right,
            row;
            left_exists = left_exists,
            right_exists = right_exists,
        )
        outside = degree - inside

        if outside >= 2
            return false
        end
    end

    return true
end

function width4_has_stable_set(cols, seedmask; required_seed = UInt64(0))
    (required_seed & ~seedmask) == 0 || throw(ArgumentError("required_seed must be a subset of seedmask"))

    states = Set{Tuple{Int, Int, Bool}}()
    push!(states, (0, 0, false))

    for col in 1:cols
        seed_column = width4_column(seedmask, cols, col)
        required_column = width4_column(required_seed, cols, col)
        next_states = Set{Tuple{Int, Int, Bool}}()

        for (prevprev, prev, seen_nonempty) in states
            for current in 0:15
                (current & seed_column) == required_column || continue

                if col >= 2 && !finalized_column_is_stable(4, prevprev, prev, current; left_exists = col >= 3)
                    continue
                end

                push!(next_states, (prev, current, seen_nonempty || current != 0))
            end
        end

        states = next_states
    end

    for (prevprev, prev, seen_nonempty) in states
        seen_nonempty || continue
        finalized_column_is_stable(4, prevprev, prev, 0; left_exists = cols >= 2, right_exists = false) || continue
        return true
    end

    return false
end

function width4_percolates_by_stable_sets(cols, seedmask)
    return !width4_has_stable_set(cols, seedmask)
end

function width4_is_minimal_percolating_by_stable_sets(cols, seedmask)
    width4_percolates_by_stable_sets(cols, seedmask) || return false

    remaining = seedmask
    while remaining != 0
        bit = remaining & -remaining
        width4_has_stable_set(cols, seedmask; required_seed = bit) || return false
        remaining &= remaining - UInt64(1)
    end

    return true
end

function stable_seed_intersection_mask(cols, col, stable_column, seedmask)
    intersection = UInt64(0)

    for row in 1:4
        column_bit(stable_column, row) || continue

        bit = UInt64(1) << bit_index(4, cols, row, col)
        if (seedmask & bit) != 0
            intersection |= bit
        end
    end

    return intersection
end

function width4_stable_witness_summary(cols, seedmask)
    states = Set{Tuple{Int, Int, UInt64, Bool}}()
    push!(states, (0, 0, UInt64(0), false))

    for col in 1:cols
        seed_column = width4_column(seedmask, cols, col)
        next_states = Set{Tuple{Int, Int, UInt64, Bool}}()

        for (prevprev, prev, hit_seed, seen_nonempty) in states
            for current in 0:15
                seed_hits = current & seed_column
                count_ones(UInt64(seed_hits)) <= 1 || continue

                current_hit = stable_seed_intersection_mask(cols, col, current, seedmask)
                if current_hit != 0 && hit_seed != 0
                    continue
                end

                if col >= 2 && !finalized_column_is_stable(4, prevprev, prev, current; left_exists = col >= 3)
                    continue
                end

                push!(next_states, (prev, current, hit_seed | current_hit, seen_nonempty || current != 0))
            end
        end

        states = next_states
    end

    has_zero_seed_obstruction = false
    witnessed_seeds = UInt64(0)

    for (prevprev, prev, hit_seed, seen_nonempty) in states
        finalized_column_is_stable(4, prevprev, prev, 0; left_exists = cols >= 2, right_exists = false) || continue

        if hit_seed == 0
            seen_nonempty && (has_zero_seed_obstruction = true)
        else
            witnessed_seeds |= hit_seed
        end
    end

    return (
        has_zero_seed_obstruction = has_zero_seed_obstruction,
        witnessed_seeds = witnessed_seeds,
    )
end

function stable_seed_hit_bit(cols, col, stable_column, seed_column, seedmask)
    seed_hits = stable_column & seed_column
    seed_hits == 0 && return UInt64(0)
    count_ones(UInt64(seed_hits)) == 1 || return nothing

    row = trailing_zeros(seed_hits) + 1
    bit = UInt64(1) << bit_index(4, cols, row, col)
    return (seedmask & bit) != 0 ? bit : UInt64(0)
end

function width4_stable_witness_summary_bits(cols, seedmask)
    states = Dict{UInt64, Width4StableBits}()
    states[UInt64(0)] = initial_stable_bits()

    for col in 1:cols
        seed_column = width4_column(seedmask, cols, col)
        next_states = Dict{UInt64, Width4StableBits}()

        for (hit_seed, bits) in states
            foreach_stable_bit_index(bits) do index
                prevprev, prev, seen_nonempty = stable_state_tuple(index)

                for current in 0:15
                    current_hit = stable_seed_hit_bit(cols, col, current, seed_column, seedmask)
                    if current_hit !== nothing && !(current_hit != 0 && hit_seed != 0)
                        if !(col >= 2 && !finalized_column_is_stable(4, prevprev, prev, current; left_exists = col >= 3))
                            next_hit = hit_seed | current_hit
                            next_index = stable_state_index(prev, current, seen_nonempty || current != 0)
                            next_bits = get(next_states, next_hit, ntuple(_ -> UInt64(0), 8))
                            next_states[next_hit] = stable_bits_add(next_bits, next_index)
                        end
                    end
                end
            end
        end

        states = next_states
    end

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

function width4_is_minimal_percolating_by_witness_summary(cols, seedmask)
    summary = width4_stable_witness_summary_bits(cols, seedmask)
    return !summary.has_zero_seed_obstruction && summary.witnessed_seeds == seedmask
end

const Width4StableBits = NTuple{8, UInt64}

function stable_state_index(prevprev, prev, seen_nonempty)
    return ((prevprev * 16 + prev) * 2 + (seen_nonempty ? 1 : 0)) + 1
end

function stable_state_tuple(index)
    zero_based = index - 1
    seen_nonempty = (zero_based & 1) == 1
    pair = zero_based >>> 1
    prev = pair % 16
    prevprev = pair ÷ 16
    return prevprev, prev, seen_nonempty
end

function stable_bits_add(bits::Width4StableBits, index)
    word_index = ((index - 1) >>> 6) + 1
    offset = (index - 1) & 63
    word = bits[word_index] | (UInt64(1) << offset)
    return Base.setindex(bits, word, word_index)
end

function stable_bits_contains(bits::Width4StableBits, index)
    word_index = ((index - 1) >>> 6) + 1
    offset = (index - 1) & 63
    return (bits[word_index] & (UInt64(1) << offset)) != 0
end

function stable_bits_indices(bits::Width4StableBits)
    indices = Int[]

    for word_index in 1:8
        word = bits[word_index]
        base = (word_index - 1) * 64

        while word != 0
            bit = word & -word
            push!(indices, base + trailing_zeros(bit) + 1)
            word &= word - UInt64(1)
        end
    end

    return indices
end

function foreach_stable_bit_index(callback, bits::Width4StableBits)
    for word_index in 1:8
        word = bits[word_index]
        base = (word_index - 1) * 64

        while word != 0
            bit = word & -word
            callback(base + trailing_zeros(bit) + 1)
            word &= word - UInt64(1)
        end
    end

    return nothing
end

function initial_stable_bits()
    return stable_bits_add(ntuple(_ -> UInt64(0), 8), stable_state_index(0, 0, false))
end

function advance_stable_bits(bits::Width4StableBits, seed_column, col)
    next_bits = ntuple(_ -> UInt64(0), 8)

    foreach_stable_bit_index(bits) do index
        prevprev, prev, seen_nonempty = stable_state_tuple(index)

        for current in 0:15
            if (current & seed_column) == 0
                if !(col >= 2 && !finalized_column_is_stable(4, prevprev, prev, current; left_exists = col >= 3))
                    next_index = stable_state_index(prev, current, seen_nonempty || current != 0)
                    next_bits = stable_bits_add(next_bits, next_index)
                end
            end
        end
    end

    return next_bits
end

function stable_bits_has_accepting_obstruction(bits::Width4StableBits, cols)
    for word_index in 1:8
        word = bits[word_index]
        base = (word_index - 1) * 64

        while word != 0
            bit = word & -word
            index = base + trailing_zeros(bit) + 1
            prevprev, prev, seen_nonempty = stable_state_tuple(index)

            if seen_nonempty && finalized_column_is_stable(4, prevprev, prev, 0; left_exists = cols >= 2, right_exists = false)
                return true
            end

            word &= word - UInt64(1)
        end
    end

    return false
end

function width4_locally_viable_percolating_count(cols, size)
    patterns = collect(0:15)
    states = Dict{Tuple{Int, Int, Int, Width4StableBits}, Int}()
    states[(0, 0, 0, initial_stable_bits())] = 1

    for col in 1:cols
        next_states = Dict{Tuple{Int, Int, Int, Width4StableBits}, Int}()

        for ((prevprev_seed, prev_seed, used, stable_bits), count) in states
            for seed_column in patterns
                new_used = used + column_seed_count(seed_column)
                new_used <= size || continue

                if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
                    continue
                end

                next_stable_bits = advance_stable_bits(stable_bits, seed_column, col)
                key = (prev_seed, seed_column, new_used, next_stable_bits)
                next_states[key] = get(next_states, key, 0) + count
            end
        end

        states = next_states
    end

    total = 0
    for ((prevprev_seed, prev_seed, used, stable_bits), count) in states
        used == size || continue
        finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, 0) || continue
        stable_bits_has_accepting_obstruction(stable_bits, cols) && continue
        total += count
    end

    return total
end

function width4_find_minimal_by_stable_witnesses(cols, size; store = true, canonical = true)
    matches = store ? UInt64[] : nothing
    generated = 0
    checked = 0
    skipped_noncanonical = 0
    percolating = 0
    raw_matches = 0
    class_matches = 0

    foreach_width4_locally_viable_sequence(cols, size) do mask
        generated += 1

        if canonical && mask != fast_canonical_rectangle_mask(4, cols, mask)
            skipped_noncanonical += 1
            return
        end

        checked += 1
        summary = width4_stable_witness_summary_bits(cols, mask)

        if summary.has_zero_seed_obstruction
            return
        end

        percolating += canonical ? fast_rectangle_orbit_size(4, cols, mask) : 1

        if summary.witnessed_seeds == mask
            class_matches += 1
            raw_matches += canonical ? fast_rectangle_orbit_size(4, cols, mask) : 1
            store && push!(matches, mask)
        end
    end

    return (
        cols = cols,
        size = size,
        generated = generated,
        checked = checked,
        skipped_noncanonical = skipped_noncanonical,
        percolating = percolating,
        raw_maximizers = raw_matches,
        symmetry_classes = class_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function width4_search_descending_by_stable_witnesses(cols; upper_size = morris_upper_bound_size(4, cols), lower_size = 1, store = true)
    total_generated = 0
    total_checked = 0
    total_percolating = 0
    generated_by_size = Pair{Int, Int}[]
    checked_by_size = Pair{Int, Int}[]
    percolating_by_size = Pair{Int, Int}[]
    minimal_by_size = Pair{Int, Int}[]

    for size in upper_size:-1:lower_size
        result = width4_find_minimal_by_stable_witnesses(cols, size; store = store)
        push!(generated_by_size, size => result.generated)
        push!(checked_by_size, size => result.checked)
        push!(percolating_by_size, size => result.percolating)
        push!(minimal_by_size, size => result.raw_maximizers)
        total_generated += result.generated
        total_checked += result.checked
        total_percolating += result.percolating

        if result.raw_maximizers > 0
            return (
                cols = cols,
                maximum_size = size,
                raw_maximizers = result.raw_maximizers,
                symmetry_classes = result.symmetry_classes,
                maximizers = result.maximizers,
                total_generated = total_generated,
                total_checked = total_checked,
                total_percolating = total_percolating,
                generated_by_size = generated_by_size,
                checked_by_size = checked_by_size,
                percolating_by_size = percolating_by_size,
                minimal_by_size = minimal_by_size,
                upper_size = upper_size,
                lower_size = lower_size,
                certified = true,
            )
        end
    end

    return (
        cols = cols,
        maximum_size = nothing,
        raw_maximizers = 0,
        symmetry_classes = 0,
        maximizers = UInt64[],
        total_generated = total_generated,
        total_checked = total_checked,
        total_percolating = total_percolating,
        generated_by_size = generated_by_size,
        checked_by_size = checked_by_size,
        percolating_by_size = percolating_by_size,
        minimal_by_size = minimal_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

if abspath(PROGRAM_FILE) == @__FILE__
    cols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 9
    size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : cols
    result = width4_find_minimal_by_stable_witnesses(cols, size; store = false)

    println("grid = 4 x ", cols)
    println("size = ", size)
    println("locally viable generated = ", result.generated)
    println("checked = ", result.checked)
    println("percolating = ", result.percolating)
    println("raw minimal percolating = ", result.raw_maximizers)
    println("symmetry classes = ", result.symmetry_classes)
end
