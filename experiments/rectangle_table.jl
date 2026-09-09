if !@isdefined(exact_search_descending)
    include("search_exact.jl")
end

function rectangle_exact_table(max_side; min_side = 2)
    min_side <= max_side || throw(ArgumentError("expected min_side <= max_side"))

    rows = NamedTuple[]

    for m in min_side:max_side
        for n in m:max_side
            upper = morris_upper_bound_size(m, n)
            result = exact_search_descending(m, n; upper_size = upper)

            push!(rows, (
                rows = m,
                cols = n,
                upper_size = upper,
                maximum_size = result.maximum_size,
                raw_maximizers = length(result.maximizers),
                total_checked = result.total_checked,
                checked_by_size = result.checked_by_size,
                certified = result.certified,
            ))
        end
    end

    return rows
end

function print_rectangle_exact_table(rows)
    println("m,n,upper_size,E_mn,raw_maximizers,total_checked,checked_by_size,certified")

    for row in rows
        checked_by_size = join(("$(size):$(checked)" for (size, checked) in row.checked_by_size), ";")
        println(
            row.rows, ",",
            row.cols, ",",
            row.upper_size, ",",
            row.maximum_size, ",",
            row.raw_maximizers, ",",
            row.total_checked, ",",
            checked_by_size, ",",
            row.certified,
        )
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    max_side = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 5
    rows = rectangle_exact_table(max_side)
    print_rectangle_exact_table(rows)
end
