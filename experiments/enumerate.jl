if !@isdefined(percolates)
    include("../src/simulation.jl")
end

if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

"""
    configuration(n, x)

Return the `n` by `n` grid encoded by the integer `x`.

The lowest `n^2` bits of `x` are read in row-major order:
bit `k` corresponds to row `div(k, n) + 1` and column `mod(k, n) + 1`.
A bit value of `1` gives an infected cell (`"X"`), and `0` gives an
uninfected cell (`"."`).
"""
function configuration(n, x)
    n <= 0 && throw(ArgumentError("n must be positive"))

    total_bits = n * n
    total = big(1) << total_bits
    0 <= x < total || throw(ArgumentError("x must satisfy 0 <= x < 2^(n^2)"))

    grid = fill(".", n, n)
    for k in 0:(total_bits - 1)
        if ((x >> k) & 1) == 1
            row = div(k, n) + 1
            col = mod(k, n) + 1
            grid[row, col] = "X"
        end
    end

    return grid
end

function count_infected(grid)
    return count(cell -> cell == "X", grid)
end

function enumerate_minimal_percolating(n)
    n <= 0 && throw(ArgumentError("n must be positive"))

    total = big(1) << (n * n)
    max_size = -1
    maximizers = Matrix{String}[]
    minimal_count = 0

    for x in 0:(total - 1)
        grid = configuration(n, x)

        if is_minimal_percolating(grid)
            minimal_count += 1
            infected = count_infected(grid)

            if infected > max_size
                max_size = infected
                empty!(maximizers)
                push!(maximizers, grid)
            elseif infected == max_size
                push!(maximizers, grid)
            end
        end
    end

    return (
        n = n,
        total_configurations = total,
        minimal_percolating_count = minimal_count,
        maximum_size = max_size,
        maximizers = maximizers,
    )
end

function print_grid(grid)
    for row in eachrow(grid)
        println(join(row, " "))
    end
end

function print_enumeration_result(result)
    println("n = ", result.n)
    println("total configurations searched: ", result.total_configurations)
    println("minimal-percolating configurations found: ", result.minimal_percolating_count)
    println("E(n): ", result.maximum_size)
    println("configurations attaining E(n): ", length(result.maximizers))

    for (i, grid) in enumerate(result.maximizers)
        println("maximizer ", i, ":")
        print_grid(grid)
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    for n in 2:4
        result = enumerate_minimal_percolating(n)
        print_enumeration_result(result)
        println()
    end
end
