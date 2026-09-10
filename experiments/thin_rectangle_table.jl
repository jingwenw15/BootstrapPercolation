if !@isdefined(exact_search_summary)
    include("search_exact.jl")
end

function thin_rectangle_pairs()
    pairs = Tuple{Int, Int}[]

    append!(pairs, [(2, n) for n in 2:12])
    append!(pairs, [(3, n) for n in 3:9])
    append!(pairs, [(4, n) for n in 4:7])

    return pairs
end

function thin_rectangle_table()
    rows = NamedTuple[]

    for (m, n) in thin_rectangle_pairs()
        upper = morris_upper_bound_size(m, n)
        result = exact_search_summary(m, n; upper_size = upper)

        push!(rows, (
            rows = m,
            cols = n,
            upper_size = upper,
            maximum_size = result.maximum_size,
            gap_from_upper = upper - result.maximum_size,
            raw_maximizers = result.raw_maximizers,
            total_checked = result.total_checked,
            checked_by_size = result.checked_by_size,
            certified = result.certified,
        ))
    end

    return rows
end

function print_thin_rectangle_table(rows)
    println("m,n,upper_size,E_mn,gap_from_upper,raw_maximizers,total_checked,checked_by_size,certified")

    for row in rows
        checked_by_size = join(("$(size):$(checked)" for (size, checked) in row.checked_by_size), ";")
        println(
            row.rows, ",",
            row.cols, ",",
            row.upper_size, ",",
            row.maximum_size, ",",
            row.gap_from_upper, ",",
            row.raw_maximizers, ",",
            row.total_checked, ",",
            checked_by_size, ",",
            row.certified,
        )
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    rows = thin_rectangle_table()
    print_thin_rectangle_table(rows)
end
