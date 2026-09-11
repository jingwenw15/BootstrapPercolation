if !@isdefined(fast_is_minimal_percolating)
    include("fast_exact.jl")
end

function removable_seed_count(rows, cols, mask, neighbors)
    removable = 0
    remaining = mask

    while remaining != 0
        bit = remaining & -remaining
        if fast_percolates(rows, cols, mask & ~bit, neighbors)
            removable += 1
        end
        remaining &= remaining - UInt64(1)
    end

    return removable
end

function removable_seed_bits(rows, cols, mask, neighbors)
    removable = UInt64[]
    remaining = mask

    while remaining != 0
        bit = remaining & -remaining
        if fast_percolates(rows, cols, mask & ~bit, neighbors)
            push!(removable, bit)
        end
        remaining &= remaining - UInt64(1)
    end

    return removable
end

function final_uninfected_count(rows, cols, mask, neighbors)
    total = rows * cols
    all_cells = total == 64 ? typemax(UInt64) : (UInt64(1) << total) - UInt64(1)
    closure = fast_closure(rows, cols, mask, neighbors)
    return count_ones(all_cells & ~closure)
end

function histogram_increment!(histogram, key)
    histogram[key] = get(histogram, key, 0) + 1
end

function sorted_histogram(histogram)
    return sort(collect(histogram); by = pair -> (pair.first isa Number ? pair.first : string(pair.first)))
end

function width4_size_obstruction_report(cols, size)
    rows = 4
    neighbors = neighbor_masks(rows, cols)

    total_checked = 0
    percolating = 0
    minimal_percolating = 0
    nonpercolating = 0
    removable_histogram = Dict{Int, Int}()
    final_uninfected_histogram = Dict{Int, Int}()

    foreach_bit_combination(rows * cols, size) do mask
        total_checked += 1

        if fast_percolates(rows, cols, mask, neighbors)
            percolating += 1
            removable = removable_seed_count(rows, cols, mask, neighbors)
            histogram_increment!(removable_histogram, removable)

            if removable == 0
                minimal_percolating += 1
            end
        else
            nonpercolating += 1
            histogram_increment!(
                final_uninfected_histogram,
                final_uninfected_count(rows, cols, mask, neighbors),
            )
        end
    end

    return (
        rows = rows,
        cols = cols,
        size = size,
        total_checked = total_checked,
        percolating = percolating,
        nonpercolating = nonpercolating,
        minimal_percolating = minimal_percolating,
        removable_histogram = sorted_histogram(removable_histogram),
        final_uninfected_histogram = sorted_histogram(final_uninfected_histogram),
    )
end

function print_width4_size_obstruction_report(report)
    println("grid = ", report.rows, " x ", report.cols)
    println("size = ", report.size)
    println("total checked: ", report.total_checked)
    println("percolating: ", report.percolating)
    println("nonpercolating: ", report.nonpercolating)
    println("minimal percolating: ", report.minimal_percolating)
    println("removable-seed histogram among percolating sets:")
    for (removable, count) in report.removable_histogram
        println("  ", removable, ": ", count)
    end
    println("final-uninfected histogram among nonpercolating sets:")
    for (uninfected, count) in report.final_uninfected_histogram
        println("  ", uninfected, ": ", count)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    cols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 8
    size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 9

    report = width4_size_obstruction_report(cols, size)
    print_width4_size_obstruction_report(report)
end
