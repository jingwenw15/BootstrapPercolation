if !@isdefined(removable_seed_bits)
    include("width4_obstruction.jl")
end

if !@isdefined(canonical_rectangle_mask)
    include("width4_analysis.jl")
end

function bit_position(rows, cols, bit)
    idx = trailing_zeros(bit)
    return (
        row = div(idx, cols) + 1,
        col = mod(idx, cols) + 1,
    )
end

function row_col_string(rows, cols, bit)
    pos = bit_position(rows, cols, bit)
    return "($(pos.row),$(pos.col))"
end

function critical_one_removable_sets_4x8()
    rows = 4
    cols = 8
    size = 9
    neighbors = neighbor_masks(rows, cols)
    critical = Tuple{UInt64, UInt64}[]

    foreach_bit_combination(rows * cols, size) do mask
        if fast_percolates(rows, cols, mask, neighbors)
            removable = removable_seed_bits(rows, cols, mask, neighbors)
            if length(removable) == 1
                push!(critical, (mask, removable[1]))
            end
        end
    end

    return critical
end

function critical_class_report()
    rows = 4
    cols = 8
    critical = critical_one_removable_sets_4x8()
    classes = Dict{UInt64, Vector{Tuple{UInt64, UInt64}}}()

    for item in critical
        mask, _ = item
        key = canonical_rectangle_mask(rows, cols, mask)
        if !haskey(classes, key)
            classes[key] = Tuple{UInt64, UInt64}[]
        end
        push!(classes[key], item)
    end

    representatives = sort(collect(keys(classes)))

    return (
        rows = rows,
        cols = cols,
        critical_count = length(critical),
        symmetry_classes = length(classes),
        representatives = representatives,
        classes = classes,
    )
end

function orbit_label_for_bit(rows, cols, bit)
    pos = bit_position(rows, cols, bit)
    row_orbit = min(pos.row, rows - pos.row + 1)
    col_orbit = min(pos.col, cols - pos.col + 1)
    return "r$(row_orbit)c$(col_orbit)"
end

function critical_summary_report()
    rows = 4
    cols = 8
    report = critical_class_report()
    orbit_counts = Dict{String, Int}()
    row_profile_counts = Dict{String, Int}()
    column_profile_counts = Dict{String, Int}()
    combined_counts = Dict{String, Int}()

    for representative in report.representatives
        items = report.classes[representative]
        removable = items[1][2]
        orbit = orbit_label_for_bit(rows, cols, removable)
        row_prof = row_profile(rows, cols, representative)
        col_prof = column_profile(rows, cols, representative)
        combined = join([orbit, row_prof, col_prof], " | ")

        orbit_counts[orbit] = get(orbit_counts, orbit, 0) + 1
        row_profile_counts[row_prof] = get(row_profile_counts, row_prof, 0) + 1
        column_profile_counts[col_prof] = get(column_profile_counts, col_prof, 0) + 1
        combined_counts[combined] = get(combined_counts, combined, 0) + 1
    end

    return (
        rows = rows,
        cols = cols,
        critical_count = report.critical_count,
        symmetry_classes = report.symmetry_classes,
        orbit_counts = sorted_count_pairs(orbit_counts),
        row_profile_counts = sorted_count_pairs(row_profile_counts),
        column_profile_counts = sorted_count_pairs(column_profile_counts),
        combined_counts = sorted_count_pairs(combined_counts),
    )
end

function sorted_count_pairs(counts)
    return sort(collect(counts); by = pair -> (-pair.second, pair.first))
end

function print_count_pairs(title, pairs; limit = typemax(Int))
    println(title)
    for (i, (item, count)) in enumerate(pairs)
        i > limit && break
        println("  ", item, ": ", count)
    end
end

function print_critical_summary_report(summary)
    println("grid = ", summary.rows, " x ", summary.cols)
    println("critical sets: ", summary.critical_count)
    println("critical symmetry classes: ", summary.symmetry_classes)
    print_count_pairs("removable seed orbit labels:", summary.orbit_counts)
    print_count_pairs("row profile counts:", summary.row_profile_counts)
    print_count_pairs("column profile counts:", summary.column_profile_counts)
    print_count_pairs("combined orbit | row profile | column profile counts:", summary.combined_counts; limit = 80)
end

function print_critical_class_report(report)
    println("grid = ", report.rows, " x ", report.cols)
    println("size = 9")
    println("percolating sets with exactly one removable seed: ", report.critical_count)
    println("rectangle symmetry classes: ", report.symmetry_classes)

    for (i, representative) in enumerate(report.representatives)
        items = report.classes[representative]
        removable_positions = sort([row_col_string(report.rows, report.cols, removable) for (_, removable) in items])

        println("class ", i, " size ", length(items))
        println("removable seed positions in orbit: ", join(removable_positions, ", "))
        print_grid(bitmask_to_grid(report.rows, report.cols, representative))
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    if length(ARGS) >= 1 && ARGS[1] == "summary"
        print_critical_summary_report(critical_summary_report())
    else
        print_critical_class_report(critical_class_report())
    end
end
