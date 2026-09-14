if !@isdefined(width4_count_minimal_by_merged_state)
    include("width4_minimality_dp.jl")
end

function width4_exact_value(cols; lower_size = 1)
    upper = morris_upper_bound_size(4, cols)
    checked = NamedTuple[]

    for size in upper:-1:lower_size
        result = width4_count_minimal_by_merged_state(cols, size)
        push!(checked, result)

        if result.raw_minimal_percolating > 0
            return (
                cols = cols,
                upper = upper,
                maximum_size = size,
                gap = upper - size,
                raw_minimal_percolating = result.raw_minimal_percolating,
                max_states = maximum(result.states_by_column),
                checked = checked,
                certified = true,
            )
        end
    end

    return (
        cols = cols,
        upper = upper,
        maximum_size = nothing,
        gap = nothing,
        raw_minimal_percolating = 0,
        max_states = maximum(maximum(result.states_by_column) for result in checked),
        checked = checked,
        certified = false,
    )
end

function width4_sequence_table(first_col, last_col)
    return [width4_exact_value(cols) for cols in first_col:last_col]
end

function print_width4_sequence_table(rows)
    println("n,upper,E_4n,gap,raw_minimal_percolating,max_states")

    for row in rows
        println(
            row.cols,
            ",",
            row.upper,
            ",",
            row.maximum_size,
            ",",
            row.gap,
            ",",
            row.raw_minimal_percolating,
            ",",
            row.max_states,
        )
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    first_col = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 4
    last_col = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 12

    print_width4_sequence_table(width4_sequence_table(first_col, last_col))
end
