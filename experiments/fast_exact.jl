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

function has_locally_forced_seed(mask, neighbors)
    remaining = mask

    while remaining != 0
        bit = remaining & -remaining
        idx = trailing_zeros(bit) + 1

        if count_ones((mask & ~bit) & neighbors[idx]) >= 2
            return true
        end

        remaining &= remaining - UInt64(1)
    end

    return false
end

function fast_transform_mask(rows, cols, mask, row_map, col_map)
    transformed = UInt64(0)

    for row in 1:rows, col in 1:cols
        bit = UInt64(1) << bit_index(rows, cols, row, col)
        if (mask & bit) != 0
            new_row = row_map(row)
            new_col = col_map(col)
            transformed |= UInt64(1) << bit_index(rows, cols, new_row, new_col)
        end
    end

    return transformed
end

function fast_rectangle_symmetry_masks(rows, cols, mask)
    return (
        mask,
        fast_transform_mask(rows, cols, mask, row -> rows - row + 1, col -> col),
        fast_transform_mask(rows, cols, mask, row -> row, col -> cols - col + 1),
        fast_transform_mask(rows, cols, mask, row -> rows - row + 1, col -> cols - col + 1),
    )
end

function fast_canonical_rectangle_mask(rows, cols, mask)
    return minimum(fast_rectangle_symmetry_masks(rows, cols, mask))
end

function fast_rectangle_orbit_size(rows, cols, mask)
    return length(Set(fast_rectangle_symmetry_masks(rows, cols, mask)))
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

function fast_find_minimal_percolating_sets_of_size_filtered(rows, cols, size; store = true)
    neighbors = neighbor_masks(rows, cols)
    matches = store ? UInt64[] : nothing
    count_matches = 0
    total_candidates = 0
    skipped_locally_forced = 0
    checked = 0

    foreach_bit_combination(rows * cols, size) do mask
        total_candidates += 1

        if has_locally_forced_seed(mask, neighbors)
            skipped_locally_forced += 1
            return
        end

        checked += 1

        if fast_is_minimal_percolating(rows, cols, mask, neighbors)
            count_matches += 1
            store && push!(matches, mask)
        end
    end

    return (
        size = size,
        total_candidates = total_candidates,
        skipped_locally_forced = skipped_locally_forced,
        checked = checked,
        raw_maximizers = count_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function fast_exact_search_descending_filtered(rows, cols; upper_size = morris_upper_bound_size(rows, cols), lower_size = 1, store = true)
    checked_by_size = Pair{Int, Int}[]
    candidates_by_size = Pair{Int, Int}[]
    skipped_locally_forced_by_size = Pair{Int, Int}[]
    total_candidates = 0
    total_checked = 0
    total_skipped_locally_forced = 0

    for size in upper_size:-1:lower_size
        result = fast_find_minimal_percolating_sets_of_size_filtered(rows, cols, size; store = store)
        push!(checked_by_size, size => result.checked)
        push!(candidates_by_size, size => result.total_candidates)
        push!(skipped_locally_forced_by_size, size => result.skipped_locally_forced)
        total_candidates += result.total_candidates
        total_checked += result.checked
        total_skipped_locally_forced += result.skipped_locally_forced

        if result.raw_maximizers > 0
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                raw_maximizers = result.raw_maximizers,
                maximizers = result.maximizers,
                total_candidates = total_candidates,
                total_checked = total_checked,
                total_skipped_locally_forced = total_skipped_locally_forced,
                candidates_by_size = candidates_by_size,
                checked_by_size = checked_by_size,
                skipped_locally_forced_by_size = skipped_locally_forced_by_size,
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
        total_candidates = total_candidates,
        total_checked = total_checked,
        total_skipped_locally_forced = total_skipped_locally_forced,
        candidates_by_size = candidates_by_size,
        checked_by_size = checked_by_size,
        skipped_locally_forced_by_size = skipped_locally_forced_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function foreach_no_locally_forced_combination(callback, total, choose, neighbors)
    choose < 0 && throw(ArgumentError("choose must be nonnegative"))
    choose > total && return nothing
    total > 64 && throw(ArgumentError("bitmask combinations support at most 64 cells"))

    chosen = UInt64(0)
    degrees = zeros(UInt8, total)

    function extend!(start, remaining)
        if remaining == 0
            callback(chosen)
            return
        end

        for idx in start:(total - remaining + 1)
            bit = UInt64(1) << (idx - 1)
            (chosen & bit) == 0 || continue
            degrees[idx] >= 2 && continue

            neighbor_bits = neighbors[idx]
            touched = Int[]
            valid = true
            scan = neighbor_bits

            while scan != 0
                neighbor_bit = scan & -scan
                neighbor_idx = trailing_zeros(neighbor_bit) + 1

                if (chosen & neighbor_bit) != 0 && degrees[neighbor_idx] + 1 >= 2
                    valid = false
                    break
                end

                push!(touched, neighbor_idx)
                scan &= scan - UInt64(1)
            end

            valid || continue

            old_chosen = chosen
            chosen |= bit
            old_degree = degrees[idx]
            degrees[idx] = old_degree

            for neighbor_idx in touched
                degrees[neighbor_idx] += UInt8(1)
            end

            extend!(idx + 1, remaining - 1)

            for neighbor_idx in touched
                degrees[neighbor_idx] -= UInt8(1)
            end

            degrees[idx] = old_degree
            chosen = old_chosen
        end
    end

    extend!(1, choose)
    return nothing
end

function fast_find_minimal_percolating_sets_of_size_generated(rows, cols, size; store = true)
    neighbors = neighbor_masks(rows, cols)
    matches = store ? UInt64[] : nothing
    generated = 0
    count_matches = 0

    foreach_no_locally_forced_combination(rows * cols, size, neighbors) do mask
        generated += 1

        if fast_is_minimal_percolating(rows, cols, mask, neighbors)
            count_matches += 1
            store && push!(matches, mask)
        end
    end

    return (
        size = size,
        generated = generated,
        raw_maximizers = count_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function fast_exact_search_descending_generated(rows, cols; upper_size = morris_upper_bound_size(rows, cols), lower_size = 1, store = true)
    generated_by_size = Pair{Int, Int}[]
    total_generated = 0

    for size in upper_size:-1:lower_size
        result = fast_find_minimal_percolating_sets_of_size_generated(rows, cols, size; store = store)
        push!(generated_by_size, size => result.generated)
        total_generated += result.generated

        if result.raw_maximizers > 0
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                raw_maximizers = result.raw_maximizers,
                maximizers = result.maximizers,
                total_generated = total_generated,
                generated_by_size = generated_by_size,
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
        total_generated = total_generated,
        generated_by_size = generated_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function fast_find_minimal_percolating_sets_of_size_generated_canonical(rows, cols, size; store = true)
    neighbors = neighbor_masks(rows, cols)
    matches = store ? UInt64[] : nothing
    generated = 0
    skipped_noncanonical = 0
    checked_representatives = 0
    raw_matches = 0
    class_matches = 0

    foreach_no_locally_forced_combination(rows * cols, size, neighbors) do mask
        generated += 1

        if mask != fast_canonical_rectangle_mask(rows, cols, mask)
            skipped_noncanonical += 1
            return
        end

        checked_representatives += 1

        if fast_is_minimal_percolating(rows, cols, mask, neighbors)
            class_matches += 1
            raw_matches += fast_rectangle_orbit_size(rows, cols, mask)
            store && push!(matches, mask)
        end
    end

    return (
        size = size,
        generated = generated,
        skipped_noncanonical = skipped_noncanonical,
        checked_representatives = checked_representatives,
        raw_maximizers = raw_matches,
        symmetry_classes = class_matches,
        maximizers = store ? matches : UInt64[],
    )
end

function fast_exact_search_descending_generated_canonical(rows, cols; upper_size = morris_upper_bound_size(rows, cols), lower_size = 1, store = true)
    generated_by_size = Pair{Int, Int}[]
    representatives_by_size = Pair{Int, Int}[]
    skipped_noncanonical_by_size = Pair{Int, Int}[]
    total_generated = 0
    total_checked_representatives = 0
    total_skipped_noncanonical = 0

    for size in upper_size:-1:lower_size
        result = fast_find_minimal_percolating_sets_of_size_generated_canonical(rows, cols, size; store = store)
        push!(generated_by_size, size => result.generated)
        push!(representatives_by_size, size => result.checked_representatives)
        push!(skipped_noncanonical_by_size, size => result.skipped_noncanonical)
        total_generated += result.generated
        total_checked_representatives += result.checked_representatives
        total_skipped_noncanonical += result.skipped_noncanonical

        if result.raw_maximizers > 0
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                raw_maximizers = result.raw_maximizers,
                symmetry_classes = result.symmetry_classes,
                maximizers = result.maximizers,
                total_generated = total_generated,
                total_checked_representatives = total_checked_representatives,
                total_skipped_noncanonical = total_skipped_noncanonical,
                generated_by_size = generated_by_size,
                representatives_by_size = representatives_by_size,
                skipped_noncanonical_by_size = skipped_noncanonical_by_size,
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
        symmetry_classes = 0,
        maximizers = UInt64[],
        total_generated = total_generated,
        total_checked_representatives = total_checked_representatives,
        total_skipped_noncanonical = total_skipped_noncanonical,
        generated_by_size = generated_by_size,
        representatives_by_size = representatives_by_size,
        skipped_noncanonical_by_size = skipped_noncanonical_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
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
