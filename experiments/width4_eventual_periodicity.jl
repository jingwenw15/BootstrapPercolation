if !@isdefined(width4_graph_acceptance_sequence)
    include("width4_graph_acceptance.jl")
end

function width4_recurrence_report(rows; period = 3, gain = 2)
    values = Dict(row.cols => row.maximum_size for row in rows)
    first_col = minimum(keys(values))
    last_col = maximum(keys(values))
    comparison_starts = [n for n in first_col:(last_col - period) if haskey(values, n + period)]

    earliest_start = nothing
    for start in comparison_starts
        if all(values[n + period] == values[n] + gain for n in comparison_starts if n >= start)
            earliest_start = start
            break
        end
    end

    failures = [
        (n = n, left = values[n], right = values[n + period])
        for n in comparison_starts
        if values[n + period] != values[n] + gain
    ]
    verified_comparisons = earliest_start === nothing ? 0 : count(n -> n >= earliest_start, comparison_starts)

    residue_corrections = Dict{Int, Set{Int}}()
    if earliest_start !== nothing
        for n in earliest_start:last_col
            haskey(values, n) || continue
            correction = period * values[n] - gain * n
            push!(get!(residue_corrections, mod(n, period), Set{Int}()), correction)
        end
    end

    return (
        period = period,
        gain = gain,
        first_col = first_col,
        last_col = last_col,
        earliest_start = earliest_start,
        verified_comparisons = verified_comparisons,
        failures = failures,
        residue_corrections = residue_corrections,
    )
end

width4_formula(cols) = fld(2 * cols + 10, 3)

function write_width4_sequence_csv(path, rows)
    open(path, "w") do io
        println(io, "n,E_4n,raw_maximizers,accepting_states,states,max_states")
        for row in rows
            println(
                io,
                row.cols,
                ",",
                row.maximum_size,
                ",",
                row.raw_maximizers,
                ",",
                row.accepting_states,
                ",",
                row.states,
                ",",
                row.max_states,
            )
        end
    end
end

function print_width4_recurrence_report(report)
    println("tested recurrence: E(4,n+", report.period, ") = E(4,n) + ", report.gain)
    println("computed range: ", report.first_col, "..", report.last_col)
    println("earliest empirical start: ", report.earliest_start)
    println("verified comparisons from start: ", report.verified_comparisons)
    println("failures before start: ", length(report.failures))
    for failure in report.failures
        println("  n=", failure.n, ": ", failure.right, " != ", failure.left, " + ", report.gain)
    end

    println("eventual affine corrections by n mod ", report.period, ":")
    for residue in sort(collect(keys(report.residue_corrections)))
        corrections = sort(collect(report.residue_corrections[residue]))
        println("  residue ", residue, ": ", join(corrections, ","))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    last_col = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 40
    first_col = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 4
    output_path = length(ARGS) >= 3 ? ARGS[3] : "experiments/results/width4_graph_acceptance_$(first_col)_to_$(last_col).csv"

    rows = width4_graph_acceptance_sequence(last_col; first_col = first_col)
    write_width4_sequence_csv(output_path, rows)
    print_width4_recurrence_report(width4_recurrence_report(rows))
    formula_failures = [row for row in rows if row.cols >= 5 && row.maximum_size != width4_formula(row.cols)]
    println("formula E(4,n) = floor((2n+10)/3) failures for n >= 5: ", length(formula_failures))
    println("sequence CSV: ", output_path)
end
