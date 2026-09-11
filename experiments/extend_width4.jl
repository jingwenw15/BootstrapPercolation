if !@isdefined(fast_find_minimal_percolating_sets_of_size_generated_canonical)
    include("fast_exact.jl")
end

function insert_empty_column_mask(rows, oldcols, mask, insert_before)
    newcols = oldcols + 1
    out = UInt64(0)

    for row in 1:rows, col in 1:oldcols
        bit = UInt64(1) << bit_index(rows, oldcols, row, col)
        if (mask & bit) != 0
            newcol = col < insert_before ? col : col + 1
            out |= UInt64(1) << bit_index(rows, newcols, row, newcol)
        end
    end

    return out
end

function find_width4_extension(oldcols, oldsize, extras)
    rows = 4
    newcols = oldcols + 1
    newsize = oldsize + extras
    reps = fast_find_minimal_percolating_sets_of_size_generated_canonical(rows, oldcols, oldsize; store = true).maximizers
    neighbors = neighbor_masks(rows, newcols)
    total = rows * newcols

    for base in reps, insert_before in 1:newcols
        placed = insert_empty_column_mask(rows, oldcols, base, insert_before)
        free = [idx for idx in 1:total if (placed & (UInt64(1) << (idx - 1))) == 0]

        if extras == 1
            for a in free
                mask = placed | (UInt64(1) << (a - 1))
                has_locally_forced_seed(mask, neighbors) && continue

                if fast_is_minimal_percolating(rows, newcols, mask, neighbors)
                    return (
                        found = true,
                        cols = newcols,
                        size = newsize,
                        insert_before = insert_before,
                        mask = mask,
                    )
                end
            end
        elseif extras == 2
            for i in 1:(length(free) - 1), j in (i + 1):length(free)
                mask = placed | (UInt64(1) << (free[i] - 1)) | (UInt64(1) << (free[j] - 1))
                has_locally_forced_seed(mask, neighbors) && continue

                if fast_is_minimal_percolating(rows, newcols, mask, neighbors)
                    return (
                        found = true,
                        cols = newcols,
                        size = newsize,
                        insert_before = insert_before,
                        mask = mask,
                    )
                end
            end
        else
            throw(ArgumentError("extras must be 1 or 2"))
        end
    end

    return (
        found = false,
        cols = newcols,
        size = newsize,
        insert_before = nothing,
        mask = UInt64(0),
    )
end

function print_extension_result(result)
    println("grid = 4 x ", result.cols)
    println("size = ", result.size)
    println("found: ", result.found)

    if result.found
        println("insert_before = ", result.insert_before)
        print_grid(bitmask_to_grid(4, result.cols, result.mask))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    oldcols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 9
    oldsize = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 9

    for extras in (2, 1)
        print_extension_result(find_width4_extension(oldcols, oldsize, extras))
    end
end
