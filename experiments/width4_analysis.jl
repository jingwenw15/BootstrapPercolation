if !@isdefined(fast_exact_search_descending)
    include("fast_exact.jl")
end

function transform_mask(rows, cols, mask, row_map, col_map)
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

function rectangle_symmetry_masks(rows, cols, mask)
    return [
        mask,
        transform_mask(rows, cols, mask, row -> rows - row + 1, col -> col),
        transform_mask(rows, cols, mask, row -> row, col -> cols - col + 1),
        transform_mask(rows, cols, mask, row -> rows - row + 1, col -> cols - col + 1),
    ]
end

function canonical_rectangle_mask(rows, cols, mask)
    return minimum(rectangle_symmetry_masks(rows, cols, mask))
end

function row_profile(rows, cols, mask)
    return join((count(col -> (mask & (UInt64(1) << bit_index(rows, cols, row, col))) != 0, 1:cols) for row in 1:rows), "-")
end

function column_profile(rows, cols, mask)
    counts = [count(row -> (mask & (UInt64(1) << bit_index(rows, cols, row, col))) != 0, 1:rows) for col in 1:cols]
    return join(counts, "")
end

function profile_counts(values)
    counts = Dict{String, Int}()
    for value in values
        counts[value] = get(counts, value, 0) + 1
    end
    return sort(collect(counts); by = pair -> (-pair.second, pair.first))
end

function width4_report(max_n)
    rows = NamedTuple[]

    for n in 4:max_n
        result = fast_exact_search_descending(4, n; store = true)
        class_counts = Dict{UInt64, Int}()

        for mask in result.maximizers
            canonical = canonical_rectangle_mask(4, n, mask)
            class_counts[canonical] = get(class_counts, canonical, 0) + 1
        end

        push!(rows, (
            n = n,
            upper_size = result.upper_size,
            maximum_size = result.maximum_size,
            gap = result.upper_size - result.maximum_size,
            raw_maximizers = result.raw_maximizers,
            symmetry_classes = length(class_counts),
            orbit_sizes = sort(collect(values(class_counts)); rev = true),
            row_profiles = profile_counts(row_profile(4, n, mask) for mask in result.maximizers),
            column_profiles = profile_counts(column_profile(4, n, mask) for mask in result.maximizers),
            representatives = sort(collect(keys(class_counts))),
        ))
    end

    return rows
end

function print_limited_profiles(title, profiles; limit = 12)
    println(title)
    for (i, (profile, count)) in enumerate(profiles)
        i > limit && break
        println("  ", profile, ": ", count)
    end
end

function print_width4_report(rows)
    for row in rows
        println("n = ", row.n)
        println("Morris upper start: ", row.upper_size)
        println("E(4,n): ", row.maximum_size)
        println("gap from upper: ", row.gap)
        println("raw maximizers: ", row.raw_maximizers)
        println("rectangle symmetry classes: ", row.symmetry_classes)
        println("orbit sizes: ", join(row.orbit_sizes, ", "))
        print_limited_profiles("row profiles:", row.row_profiles)
        print_limited_profiles("column profiles:", row.column_profiles)
        println("first representatives:")

        for (i, mask) in enumerate(row.representatives)
            i > 8 && break
            println("representative ", i, ":")
            print_grid(bitmask_to_grid(4, row.n, mask))
        end

        println()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    max_n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 8
    print_width4_report(width4_report(max_n))
end
