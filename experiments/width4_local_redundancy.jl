if !@isdefined(fast_percolates)
    include("fast_exact.jl")
end

function seed_neighbor_count(mask, neighbors, bit)
    idx = trailing_zeros(bit) + 1
    return count_ones(mask & neighbors[idx])
end

function locally_forced_seed_count(mask, neighbors)
    count = 0
    remaining = mask

    while remaining != 0
        bit = remaining & -remaining
        if seed_neighbor_count(mask, neighbors, bit) >= 2
            count += 1
        end
        remaining &= remaining - UInt64(1)
    end

    return count
end

function width4_size9_local_redundancy_report()
    rows = 4
    cols = 8
    size = 9
    neighbors = neighbor_masks(rows, cols)
    percolating = 0
    histogram = Dict{Int, Int}()
    no_local_forced_examples = UInt64[]

    foreach_bit_combination(rows * cols, size) do mask
        if fast_percolates(rows, cols, mask, neighbors)
            percolating += 1
            local_count = locally_forced_seed_count(mask, neighbors)
            histogram[local_count] = get(histogram, local_count, 0) + 1

            if local_count == 0 && length(no_local_forced_examples) < 20
                push!(no_local_forced_examples, mask)
            end
        end
    end

    return (
        percolating = percolating,
        histogram = sort(collect(histogram); by = pair -> pair.first),
        no_local_forced_examples = no_local_forced_examples,
    )
end

function print_width4_size9_local_redundancy_report(report)
    println("grid = 4 x 8")
    println("size = 9")
    println("percolating sets: ", report.percolating)
    println("locally forced seed count histogram:")
    for (local_count, count) in report.histogram
        println("  ", local_count, ": ", count)
    end

    if !isempty(report.no_local_forced_examples)
        println("examples with no locally forced seed:")
        for (i, mask) in enumerate(report.no_local_forced_examples)
            println("example ", i, ":")
            print_grid(bitmask_to_grid(4, 8, mask))
        end
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    print_width4_size9_local_redundancy_report(width4_size9_local_redundancy_report())
end
