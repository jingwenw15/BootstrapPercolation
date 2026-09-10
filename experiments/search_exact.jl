if !@isdefined(enumerate_minimal_percolating)
    include("enumerate.jl")
end

function morris_upper_bound_size(n)
    n <= 0 && throw(ArgumentError("n must be positive"))
    return morris_upper_bound_size(n, n)
end

function morris_upper_bound_size(rows, cols)
    rows <= 0 && throw(ArgumentError("rows must be positive"))
    cols <= 0 && throw(ArgumentError("cols must be positive"))
    return fld((rows + 2) * (cols + 2), 6)
end

function grid_from_positions(rows, cols, positions)
    grid = fill(".", rows, cols)

    for position in positions
        row = div(position - 1, cols) + 1
        col = mod(position - 1, cols) + 1
        grid[row, col] = "X"
    end

    return grid
end

function grid_from_positions(n, positions)
    return grid_from_positions(n, n, positions)
end

function foreach_combination(callback, total, choose)
    choose < 0 && throw(ArgumentError("choose must be nonnegative"))
    choose > total && return nothing

    current = Vector{Int}(undef, choose)

    function extend!(start, depth)
        if depth > choose
            callback(current)
            return
        end

        remaining = choose - depth
        for value in start:(total - remaining)
            current[depth] = value
            extend!(value + 1, depth + 1)
        end
    end

    extend!(1, 1)
    return nothing
end

function find_minimal_percolating_sets_of_size(rows, cols, size)
    total_cells = rows * cols
    matches = Matrix{String}[]
    checked = 0

    foreach_combination(total_cells, size) do positions
        checked += 1
        grid = grid_from_positions(rows, cols, positions)

        if is_minimal_percolating(grid)
            push!(matches, grid)
        end
    end

    return matches, checked
end

function find_minimal_percolating_sets_of_size(n, size)
    return find_minimal_percolating_sets_of_size(n, n, size)
end

function exact_search_descending(rows, cols; upper_size = rows * cols, lower_size = 1)
    rows <= 0 && throw(ArgumentError("rows must be positive"))
    cols <= 0 && throw(ArgumentError("cols must be positive"))
    0 <= lower_size <= upper_size <= rows * cols ||
        throw(ArgumentError("expected 0 <= lower_size <= upper_size <= rows * cols"))

    checked_by_size = Pair{Int, Int}[]
    total_checked = 0

    for size in upper_size:-1:lower_size
        matches, checked = find_minimal_percolating_sets_of_size(rows, cols, size)
        push!(checked_by_size, size => checked)
        total_checked += checked

        if !isempty(matches)
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                maximizers = matches,
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
        maximizers = Matrix{String}[],
        total_checked = total_checked,
        checked_by_size = checked_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function exact_search_descending(n; upper_size = n * n, lower_size = 1)
    return exact_search_descending(n, n; upper_size = upper_size, lower_size = lower_size)
end

function exact_search_summary(rows, cols; upper_size = rows * cols, lower_size = 1)
    rows <= 0 && throw(ArgumentError("rows must be positive"))
    cols <= 0 && throw(ArgumentError("cols must be positive"))
    0 <= lower_size <= upper_size <= rows * cols ||
        throw(ArgumentError("expected 0 <= lower_size <= upper_size <= rows * cols"))

    checked_by_size = Pair{Int, Int}[]
    total_checked = 0

    for size in upper_size:-1:lower_size
        checked = 0
        matches = 0

        foreach_combination(rows * cols, size) do positions
            checked += 1
            grid = grid_from_positions(rows, cols, positions)

            if is_minimal_percolating(grid)
                matches += 1
            end
        end

        push!(checked_by_size, size => checked)
        total_checked += checked

        if matches > 0
            return (
                rows = rows,
                cols = cols,
                maximum_size = size,
                raw_maximizers = matches,
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
        total_checked = total_checked,
        checked_by_size = checked_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function exact_search_summary(n; upper_size = n * n, lower_size = 1)
    return exact_search_summary(n, n; upper_size = upper_size, lower_size = lower_size)
end

function print_exact_search_result(result)
    if result.rows == result.cols
        println("n = ", result.rows)
    else
        println("grid = ", result.rows, " x ", result.cols)
    end

    println("search size range: ", result.upper_size, " down to ", result.lower_size)
    println("total configurations checked in size-ordered search: ", result.total_checked)
    println("checked by size:")
    for (size, checked) in result.checked_by_size
        println("  size ", size, ": ", checked)
    end

    if result.certified
        println("E(n): ", result.maximum_size)
        println("configurations attaining E(n): ", length(result.maximizers))
        println("single-removal verification passed: ", isempty(verify_reported_maximizers(result)))

        for (i, grid) in enumerate(result.maximizers)
            println("maximizer ", i, ":")
            print_grid(grid)
        end
    else
        println("no minimal-percolating configuration found in searched range")
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    rows = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 5
    cols = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : rows
    upper_size = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : morris_upper_bound_size(rows, cols)

    println("Using Morris upper bound start size floor((rows + 2)(cols + 2) / 6) = ", upper_size)
    result = exact_search_descending(rows, cols; upper_size = upper_size)
    print_exact_search_result(result)
end
