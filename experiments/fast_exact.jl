if !@isdefined(morris_upper_bound_size)
    include("search_exact.jl")
end

function bit_index(rows, cols, row, col)
    return (row - 1) * cols + (col - 1)
end

function bitmask_from_positions(rows, cols, positions)
    mask = UInt64(0)

    for position in positions
        row = div(position - 1, cols) + 1
        col = mod(position - 1, cols) + 1
        mask |= UInt64(1) << bit_index(rows, cols, row, col)
    end

    return mask
end

function bitmask_to_grid(rows, cols, mask)
    grid = fill(".", rows, cols)

    for row in 1:rows, col in 1:cols
        bit = UInt64(1) << bit_index(rows, cols, row, col)
        if (mask & bit) != 0
            grid[row, col] = "X"
        end
    end

    return grid
end

function neighbor_masks(rows, cols)
    total = rows * cols
    total <= 64 || throw(ArgumentError("bitmask search supports at most 64 cells"))

    masks = fill(UInt64(0), total)

    for row in 1:rows, col in 1:cols
        idx = bit_index(rows, cols, row, col) + 1

        for (dr, dc) in ((1, 0), (-1, 0), (0, 1), (0, -1))
            nr = row + dr
            nc = col + dc

            if 1 <= nr <= rows && 1 <= nc <= cols
                masks[idx] |= UInt64(1) << bit_index(rows, cols, nr, nc)
            end
        end
    end

    return masks
end

function fast_closure(rows, cols, mask, neighbors)
    total = rows * cols
    all_cells = total == 64 ? typemax(UInt64) : (UInt64(1) << total) - UInt64(1)
    state = mask

    while true
        next_state = state
        healthy = all_cells & ~state

        for idx in 1:total
            bit = UInt64(1) << (idx - 1)
            if (healthy & bit) != 0 && count_ones(state & neighbors[idx]) >= 2
                next_state |= bit
            end
        end

        next_state == state && return state
        state = next_state
    end
end

function fast_percolates(rows, cols, mask, neighbors = neighbor_masks(rows, cols))
    total = rows * cols
    all_cells = total == 64 ? typemax(UInt64) : (UInt64(1) << total) - UInt64(1)
    return fast_closure(rows, cols, mask, neighbors) == all_cells
end

function fast_is_minimal_percolating(rows, cols, mask, neighbors = neighbor_masks(rows, cols))
    fast_percolates(rows, cols, mask, neighbors) || return false

    remaining = mask
    while remaining != 0
        bit = remaining & -remaining
        if fast_percolates(rows, cols, mask & ~bit, neighbors)
            return false
        end
        remaining &= remaining - UInt64(1)
    end

    return true
end

function next_combination(mask)
    smallest = mask & -mask
    ripple = mask + smallest
    ones = ((ripple ⊻ mask) >> 2) ÷ smallest
    return ripple | ones
end

function foreach_bit_combination(callback, total, choose)
    choose < 0 && throw(ArgumentError("choose must be nonnegative"))
    choose > total && return nothing
    choose == 0 && (callback(UInt64(0)); return nothing)
    total > 64 && throw(ArgumentError("bitmask combinations support at most 64 cells"))

    limit = UInt64(1) << total
    mask = (UInt64(1) << choose) - UInt64(1)

    while mask < limit
        callback(mask)
        mask = next_combination(mask)
    end

    return nothing
end

function fast_find_minimal_percolating_sets_of_size(rows, cols, size; store = true)
    neighbors = neighbor_masks(rows, cols)
    matches = store ? UInt64[] : nothing
    count_matches = 0
    checked = 0

    foreach_bit_combination(rows * cols, size) do mask
        checked += 1

        if fast_is_minimal_percolating(rows, cols, mask, neighbors)
            count_matches += 1
            store && push!(matches, mask)
        end
    end

    return (
        size = size,
        checked = checked,
        raw_maximizers = count_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function fast_exact_search_descending(rows, cols; upper_size = morris_upper_bound_size(rows, cols), lower_size = 1, store = true)
    checked_by_size = Pair{Int, Int}[]
    total_checked = 0

    for size in upper_size:-1:lower_size
        result = fast_find_minimal_percolating_sets_of_size(rows, cols, size; store = store)
        push!(checked_by_size, size => result.checked)
        total_checked += result.checked

        if result.raw_maximizers > 0
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                raw_maximizers = result.raw_maximizers,
                maximizers = result.maximizers,
                total_checked = total_checked,
                checked_by_size = checked_by_size,
                upper_size = upper_size,
                lower_size = lower_size,
                certified = true,
            )
        end
    end

    return (
        rows = rows,
        cols = cols,
        maximum_size = nothing,
        raw_maximizers = 0,
        maximizers = UInt64[],
        total_checked = total_checked,
        checked_by_size = checked_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function print_fast_exact_result(result)
    println("grid = ", result.rows, " x ", result.cols)
    println("search size range: ", result.upper_size, " down to ", result.lower_size)
    println("total configurations checked: ", result.total_checked)
    println("checked by size:")
    for (size, checked) in result.checked_by_size
        println("  size ", size, ": ", checked)
    end
    println("certified: ", result.certified)
    println("E(m,n): ", result.maximum_size)
    println("raw maximizers: ", result.raw_maximizers)

    for (i, mask) in enumerate(result.maximizers)
        println("maximizer ", i, ":")
        print_grid(bitmask_to_grid(result.rows, result.cols, mask))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    rows = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 4
    cols = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 8
    upper_size = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : morris_upper_bound_size(rows, cols)

    result = fast_exact_search_descending(rows, cols; upper_size = upper_size)
    print_fast_exact_result(result)
end
