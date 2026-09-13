if !@isdefined(fast_is_minimal_percolating)
    include("fast_exact.jl")
end

function column_seed_count(column)
    return count_ones(UInt64(column))
end

function column_bit(column, row)
    return (column & (1 << (row - 1))) != 0
end

function local_seed_degree(rows, left, center, right, row)
    degree = 0

    if row > 1 && column_bit(center, row - 1)
        degree += 1
    end

    if row < rows && column_bit(center, row + 1)
        degree += 1
    end

    if column_bit(left, row)
        degree += 1
    end

    if column_bit(right, row)
        degree += 1
    end

    return degree
end

function finalized_column_has_no_forced_seed(rows, left, center, right)
    for row in 1:rows
        if column_bit(center, row) && local_seed_degree(rows, left, center, right, row) >= 2
            return false
        end
    end

    return true
end

function append_column_mask(rows, cols, current_mask, col, column)
    mask = current_mask

    for row in 1:rows
        if column_bit(column, row)
            mask |= UInt64(1) << bit_index(rows, cols, row, col)
        end
    end

    return mask
end

function foreach_width4_locally_viable_sequence(callback, cols, size)
    rows = 4
    patterns = collect(0:((1 << rows) - 1))

    function extend(col, prevprev, prev, used, mask)
        if col > cols
            used == size || return
            finalized_column_has_no_forced_seed(rows, prevprev, prev, 0) || return
            callback(mask)
            return
        end

        for current in patterns
            new_used = used + column_seed_count(current)
            new_used <= size || continue

            if col >= 2 && !finalized_column_has_no_forced_seed(rows, prevprev, prev, current)
                continue
            end

            new_mask = append_column_mask(rows, cols, mask, col, current)
            extend(col + 1, prev, current, new_used, new_mask)
        end
    end

    extend(1, 0, 0, 0, UInt64(0))
    return nothing
end

function width4_locally_viable_count(cols, size)
    rows = 4
    patterns = collect(0:((1 << rows) - 1))
    states = Dict{Tuple{Int, Int, Int}, Int}()
    states[(0, 0, 0)] = 1

    for col in 1:cols
        next_states = Dict{Tuple{Int, Int, Int}, Int}()

        for ((prevprev, prev, used), count) in states
            for current in patterns
                new_used = used + column_seed_count(current)
                new_used <= size || continue

                if col >= 2 && !finalized_column_has_no_forced_seed(rows, prevprev, prev, current)
                    continue
                end

                key = (prev, current, new_used)
                next_states[key] = get(next_states, key, 0) + count
            end
        end

        states = next_states
    end

    total = 0
    for ((prevprev, prev, used), count) in states
        used == size || continue
        finalized_column_has_no_forced_seed(rows, prevprev, prev, 0) || continue
        total += count
    end

    return total
end

function width4_transfer_find_minimal_percolating(cols, size; store = true, canonical = true)
    rows = 4
    neighbors = neighbor_masks(rows, cols)
    matches = store ? UInt64[] : nothing
    generated = 0
    checked = 0
    skipped_noncanonical = 0
    raw_matches = 0
    class_matches = 0

    foreach_width4_locally_viable_sequence(cols, size) do mask
        generated += 1

        if canonical && mask != fast_canonical_rectangle_mask(rows, cols, mask)
            skipped_noncanonical += 1
            return
        end

        checked += 1

        if fast_is_minimal_percolating(rows, cols, mask, neighbors)
            class_matches += 1
            raw_matches += canonical ? fast_rectangle_orbit_size(rows, cols, mask) : 1
            store && push!(matches, mask)
        end
    end

    return (
        cols = cols,
        size = size,
        generated = generated,
        checked = checked,
        skipped_noncanonical = skipped_noncanonical,
        raw_maximizers = raw_matches,
        symmetry_classes = class_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function print_width4_transfer_result(result)
    println("grid = 4 x ", result.cols)
    println("size = ", result.size)
    println("locally viable generated = ", result.generated)
    println("checked = ", result.checked)
    println("skipped noncanonical = ", result.skipped_noncanonical)
    println("raw minimal percolating = ", result.raw_maximizers)
    println("symmetry classes = ", result.symmetry_classes)

    for (i, mask) in enumerate(result.maximizers)
        println("representative ", i, ":")
        print_grid(bitmask_to_grid(4, result.cols, mask))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    cols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 10
    size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : cols
    store = length(ARGS) >= 3 ? parse(Bool, ARGS[3]) : false

    print_width4_transfer_result(width4_transfer_find_minimal_percolating(cols, size; store = store))
end
