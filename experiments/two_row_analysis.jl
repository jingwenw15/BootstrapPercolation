if !@isdefined(exact_search_descending)
    include("search_exact.jl")
end

function column_words(grid)
    rows, cols = size(grid)
    rows == 2 || throw(ArgumentError("expected a 2 x n grid"))

    return [join((grid[i, j] == "X" ? "1" : "0" for i in 1:rows), "") for j in 1:cols]
end

function two_row_key(grid)
    return join(column_words(grid), " ")
end

function flip_rows(grid)
    rows, cols = size(grid)
    return [grid[rows - i + 1, j] for i in 1:rows, j in 1:cols]
end

function reverse_columns(grid)
    rows, cols = size(grid)
    return [grid[i, cols - j + 1] for i in 1:rows, j in 1:cols]
end

function two_row_symmetries(grid)
    return [
        copy(grid),
        flip_rows(grid),
        reverse_columns(grid),
        flip_rows(reverse_columns(grid)),
    ]
end

function two_row_canonical_key(grid)
    return minimum(two_row_key(symmetry) for symmetry in two_row_symmetries(grid))
end

function two_row_classes(grids)
    classes = Dict{String, Int}()

    for grid in grids
        key = two_row_canonical_key(grid)
        classes[key] = get(classes, key, 0) + 1
    end

    return classes
end

function column_count_summary(words)
    counts = Dict(word => count(==(word), words) for word in ["00", "01", "10", "11"])
    return join(("$(word):$(counts[word])" for word in ["00", "01", "10", "11"]), " ")
end

function two_row_analysis(max_n)
    rows = NamedTuple[]

    for n in 2:max_n
        result = exact_search_descending(2, n; upper_size = morris_upper_bound_size(2, n))
        classes = two_row_classes(result.maximizers)
        representatives = sort(collect(keys(classes)))

        push!(rows, (
            n = n,
            maximum_size = result.maximum_size,
            upper_size = result.upper_size,
            raw_maximizers = length(result.maximizers),
            symmetry_classes = length(classes),
            representatives = representatives,
            class_sizes = [classes[key] for key in representatives],
        ))
    end

    return rows
end

function print_two_row_analysis(rows)
    for row in rows
        println("n = ", row.n)
        println("upper size: ", row.upper_size)
        println("E(2,n): ", row.maximum_size)
        println("raw maximizers: ", row.raw_maximizers)
        println("rectangle symmetry classes: ", row.symmetry_classes)

        for (i, representative) in enumerate(row.representatives)
            println("class ", i, " size ", row.class_sizes[i], ": ", representative)
            println("  column counts: ", column_count_summary(split(representative)))
        end
        println()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    max_n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 12
    print_two_row_analysis(two_row_analysis(max_n))
end
