if !@isdefined(critical_class_report)
    include("width4_critical_sets.jl")
end

function infection_times(rows, cols, mask)
    grid = bitmask_to_grid(rows, cols, mask)
    _, _, _, history = simulate(grid)
    times = fill(-1, rows, cols)

    for (t, state) in enumerate(history)
        for row in 1:rows, col in 1:cols
            if state[row, col] == "X" && times[row, col] == -1
                times[row, col] = t - 1
            end
        end
    end

    return times
end

function print_int_grid(grid)
    for row in eachrow(grid)
        println(join(row, " "))
    end
end

function representative_by_orbit()
    report = critical_class_report()
    rows = report.rows
    cols = report.cols
    representatives = Dict{String, Tuple{UInt64, UInt64}}()

    for representative in report.representatives
        items = report.classes[representative]
        removable = items[1][2]
        orbit = orbit_label_for_bit(rows, cols, removable)

        if !haskey(representatives, orbit)
            representatives[orbit] = (representative, removable)
        end
    end

    return sort(collect(representatives); by = pair -> pair.first)
end

function infection_time_of_bit(rows, cols, mask, bit)
    times = infection_times(rows, cols, mask)
    pos = bit_position(rows, cols, bit)
    return times[pos.row, pos.col]
end

function removed_seed_reinfection_histogram()
    rows = 4
    cols = 8
    histogram = Dict{Int, Int}()

    for (mask, removable) in critical_one_removable_sets_4x8()
        reduced = mask & ~removable
        time = infection_time_of_bit(rows, cols, reduced, removable)
        histogram[time] = get(histogram, time, 0) + 1
    end

    return sort(collect(histogram); by = pair -> pair.first)
end

function print_critical_dynamics_report()
    rows = 4
    cols = 8

    for (orbit, (mask, removable)) in representative_by_orbit()
        reduced = mask & ~removable

        println("orbit = ", orbit)
        println("removable seed = ", row_col_string(rows, cols, removable))
        println("original grid:")
        print_grid(bitmask_to_grid(rows, cols, mask))
        println("original infection times:")
        print_int_grid(infection_times(rows, cols, mask))
        println("after removing seed:")
        print_grid(bitmask_to_grid(rows, cols, reduced))
        println("reduced infection times:")
        print_int_grid(infection_times(rows, cols, reduced))
        println()
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 1 && ARGS[1] == "reinfection"
        println("removed seed reinfection time histogram:")
        for (time, count) in removed_seed_reinfection_histogram()
            println("  ", time, ": ", count)
        end
    else
        print_critical_dynamics_report()
    end
end
