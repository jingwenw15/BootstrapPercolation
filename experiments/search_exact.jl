if !@isdefined(enumerate_minimal_percolating)
    include("enumerate.jl")
end

function morris_upper_bound_size(n)
    n <= 0 && throw(ArgumentError("n must be positive"))
    return fld((n + 2)^2, 6)
end

function grid_from_positions(n, positions)
    grid = fill(".", n, n)

    for position in positions
        row = div(position - 1, n) + 1
        col = mod(position - 1, n) + 1
        grid[row, col] = "X"
    end

    return grid
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

function find_minimal_percolating_sets_of_size(n, size)
    total_cells = n * n
    matches = Matrix{String}[]
    checked = 0

    foreach_combination(total_cells, size) do positions
        checked += 1
        grid = grid_from_positions(n, positions)

        if is_minimal_percolating(grid)
            push!(matches, grid)
        end
    end

    return matches, checked
end

function exact_search_descending(n; upper_size = n * n, lower_size = 1)
    n <= 0 && throw(ArgumentError("n must be positive"))
    0 <= lower_size <= upper_size <= n * n ||
        throw(ArgumentError("expected 0 <= lower_size <= upper_size <= n^2"))

    checked_by_size = Pair{Int, Int}[]
    total_checked = 0

    for size in upper_size:-1:lower_size
        matches, checked = find_minimal_percolating_sets_of_size(n, size)
        push!(checked_by_size, size => checked)
        total_checked += checked

        if !isempty(matches)
            return (
                n = n,
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
        n = n,
        maximum_size = nothing,
        maximizers = Matrix{String}[],
        total_checked = total_checked,
        checked_by_size = checked_by_size,
        upper_size = upper_size,
        lower_size = lower_size,
        certified = false,
    )
end

function print_exact_search_result(result)
    println("n = ", result.n)
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
    n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 5
    upper_size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : morris_upper_bound_size(n)

    println("Using Morris upper bound start size floor((n + 2)^2 / 6) = ", upper_size)
    result = exact_search_descending(n; upper_size = upper_size)
    print_exact_search_result(result)
end
