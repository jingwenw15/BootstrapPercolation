if !@isdefined(enumerate_minimal_percolating)
    include("enumerate.jl")
end

function require_square_grid(grid)
    R, C = size(grid)
    R == C || throw(ArgumentError("grid must be square"))
    return R
end

function grid_key(grid)
    R, C = size(grid)
    rows = String[]

    for i in 1:R
        push!(rows, join((grid[i, j] for j in 1:C), ""))
    end

    return join(rows, "/")
end

function square_symmetries(grid)
    n = require_square_grid(grid)

    return [
        copy(grid),
        [grid[n - j + 1, i] for i in 1:n, j in 1:n],
        [grid[n - i + 1, n - j + 1] for i in 1:n, j in 1:n],
        [grid[j, n - i + 1] for i in 1:n, j in 1:n],
        [grid[i, n - j + 1] for i in 1:n, j in 1:n],
        [grid[n - i + 1, j] for i in 1:n, j in 1:n],
        [grid[j, i] for i in 1:n, j in 1:n],
        [grid[n - j + 1, n - i + 1] for i in 1:n, j in 1:n],
    ]
end

function canonical_key(grid)
    return minimum(grid_key(symmetry) for symmetry in square_symmetries(grid))
end

function canonical_grid(grid)
    candidates = square_symmetries(grid)
    keys = grid_key.(candidates)
    return candidates[argmin(keys)]
end

function symmetry_classes(grids)
    classes = Dict{String, Vector{Matrix{String}}}()

    for grid in grids
        key = canonical_key(grid)
        if !haskey(classes, key)
            classes[key] = Matrix{String}[]
        end
        push!(classes[key], grid)
    end

    return classes
end

function symmetry_class_report(n)
    result = enumerate_minimal_percolating(n)
    classes = symmetry_classes(result.maximizers)

    representatives = sort(
        [canonical_grid(grids[1]) for grids in values(classes)];
        by = grid_key,
    )

    return (
        n = n,
        maximum_size = result.maximum_size,
        raw_maximizers = length(result.maximizers),
        symmetry_classes = length(classes),
        class_sizes = sort([length(grids) for grids in values(classes)]; rev = true),
        representatives = representatives,
    )
end

function print_symmetry_class_report(report)
    println("n = ", report.n)
    println("E(n): ", report.maximum_size)
    println("raw maximizers: ", report.raw_maximizers)
    println("symmetry classes: ", report.symmetry_classes)
    println("class sizes: ", join(report.class_sizes, ", "))

    for (i, representative) in enumerate(report.representatives)
        println("class representative ", i, ":")
        print_grid(representative)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    for n in 2:4
        report = symmetry_class_report(n)
        print_symmetry_class_report(report)
        println()
    end
end
