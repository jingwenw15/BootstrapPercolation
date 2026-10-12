if !@isdefined(width4_count_minimal_by_merged_state)
    include("width4_minimality_dp.jl")
end

function width4_merged_state_profile(cols, size)
    patterns = collect(0:15)
    initial_nohit = initial_stable_bits()
    initial_obligations = Tuple(Width4StableBits[])
    states = Dict{Tuple{Int, Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}, Int}()
    states[(0, 0, 0, initial_nohit, initial_obligations)] = 1
    rows = NamedTuple[]

    for col in 1:cols
        next_states = Dict{Tuple{Int, Int, Int, Width4StableBits, Tuple{Vararg{Width4StableBits}}}, Int}()
        attempted = 0
        kept = 0
        pruned_size = 0
        pruned_forced_seed = 0
        pruned_zero_obstruction = 0
        pruned_unwitnessable = 0

        for ((prevprev_seed, prev_seed, used, nohit_bits, obligations), count) in states
            for seed_column in patterns
                attempted += 1
                new_used = used + column_seed_count(seed_column)

                if new_used > size
                    pruned_size += 1
                    continue
                end

                if col >= 2 && !finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, seed_column)
                    pruned_forced_seed += 1
                    continue
                end

                next_nohit = advance_stable_bits(nohit_bits, seed_column, col)
                if stable_bits_can_close(next_nohit, col; right_exists = col < cols)
                    pruned_zero_obstruction += 1
                    continue
                end

                next_obligations = advance_obligations(obligations, seed_column, col)
                next_obligations = add_current_seed_obligations(next_obligations, nohit_bits, cols, col, seed_column)
                normalized = normalize_obligations(next_obligations, col, cols)

                if normalized === nothing
                    pruned_unwitnessable += 1
                    continue
                end

                key = (prev_seed, seed_column, new_used, next_nohit, normalized)
                next_states[key] = get(next_states, key, 0) + count
                kept += 1
            end
        end

        push!(
            rows,
            (
                column = col,
                states_before = length(states),
                attempted = attempted,
                kept = kept,
                pruned_size = pruned_size,
                pruned_forced_seed = pruned_forced_seed,
                pruned_zero_obstruction = pruned_zero_obstruction,
                pruned_unwitnessable = pruned_unwitnessable,
                states_after = length(next_states),
            ),
        )

        states = next_states
    end

    accepted_states = 0
    accepted_count = 0

    for ((prevprev_seed, prev_seed, used, nohit_bits, obligations), count) in states
        used == size || continue
        finalized_column_has_no_forced_seed(4, prevprev_seed, prev_seed, 0) || continue
        stable_bits_can_close(nohit_bits, cols; right_exists = false) && continue

        normalized = normalize_obligations(obligations, cols, cols)
        normalized === nothing && continue
        isempty(normalized) || continue

        accepted_states += 1
        accepted_count += count
    end

    return (
        cols = cols,
        size = size,
        rows = rows,
        accepted_states = accepted_states,
        accepted_count = accepted_count,
    )
end

function print_width4_merged_state_profile(profile)
    println("grid = 4 x ", profile.cols)
    println("size = ", profile.size)
    println("accepted states = ", profile.accepted_states)
    println("accepted raw minimal percolating = ", profile.accepted_count)
    println("column,states_before,attempted,kept,pruned_size,pruned_forced_seed,pruned_zero_obstruction,pruned_unwitnessable,states_after")

    for row in profile.rows
        println(
            row.column,
            ",",
            row.states_before,
            ",",
            row.attempted,
            ",",
            row.kept,
            ",",
            row.pruned_size,
            ",",
            row.pruned_forced_seed,
            ",",
            row.pruned_zero_obstruction,
            ",",
            row.pruned_unwitnessable,
            ",",
            row.states_after,
        )
    end
end

if abspath(PROGRAM_FILE) == @__FILE__
    cols = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 12
    size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 11

    print_width4_merged_state_profile(width4_merged_state_profile(cols, size))
end
