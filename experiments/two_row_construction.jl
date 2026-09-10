if !@isdefined(is_minimal_percolating)
    include("../src/minimal.jl")
end

if !@isdefined(morris_upper_bound_size)
    include("search_exact.jl")
end

function grid_from_column_words(words)
    cols = length(words)
    grid = fill(".", 2, cols)

    for (j, word) in enumerate(words)
        length(word) == 2 || throw(ArgumentError("column words must have length 2"))
        for i in 1:2
            if word[i] == '1'
                grid[i, j] = "X"
            elseif word[i] != '0'
                throw(ArgumentError("column words must use only 0 and 1"))
            end
        end
    end

    return grid
end

function two_row_extremal_words(n)
    n < 2 && throw(ArgumentError("n must be at least 2"))

    block = ["01", "01", "00"]
    words = String[]

    if n % 3 == 0
        for _ in 1:(div(n, 3) - 1)
            append!(words, block)
        end
        append!(words, ["01", "00", "11"])
    elseif n % 3 == 1
        for _ in 1:div(n - 1, 3)
            append!(words, block)
        end
        push!(words, "11")
    else
        for _ in 1:div(n - 2, 3)
            append!(words, block)
        end
        append!(words, ["01", "10"])
    end

    return words
end

function two_row_extremal_construction(n)
    return grid_from_column_words(two_row_extremal_words(n))
end

function print_two_row_construction(n)
    grid = two_row_extremal_construction(n)
    println("n = ", n)
    println("column words: ", join(two_row_extremal_words(n), " "))
    println("size: ", count_infected(grid))
    println("Morris upper bound: ", morris_upper_bound_size(2, n))
    println("minimal percolating: ", is_minimal_percolating(grid))
    print_grid(grid)
end

if abspath(PROGRAM_FILE) == @__FILE__
    max_n = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 12

    for n in 2:max_n
        print_two_row_construction(n)
        println()
    end
end
