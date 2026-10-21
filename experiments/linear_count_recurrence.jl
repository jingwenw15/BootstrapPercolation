# Modular fitting proposes a recurrence. Only the exact finite-dimensional
# identity checked below certifies it; matching a short prefix is insufficient.
function count_recurrence_mod(sequence, prime)
    2 <= prime <= 1_100_000_000 || throw(ArgumentError("prime must fit the supported arithmetic range"))
    coefficients, previous = [1], [1]
    order, shift, discrepancy = 0, 1, 1
    for n in 0:(length(sequence) - 1)
        delta = mod(sequence[n + 1], prime)
        for i in 1:order
            delta = mod(delta + coefficients[i + 1] * mod(sequence[n - i + 1], prime), prime)
        end
        if delta == 0
            shift += 1
            continue
        end
        saved = copy(coefficients)
        scale = mod(delta * invmod(discrepancy, prime), prime)
        while length(coefficients) < length(previous) + shift
            push!(coefficients, 0)
        end
        for i in eachindex(previous)
            coefficients[i + shift] = mod(coefficients[i + shift] - scale * previous[i], prime)
        end
        if 2 * order <= n
            order = n + 1 - order
            previous, discrepancy, shift = saved, delta, 1
        else
            shift += 1
        end
    end
    return [mod(-coefficients[i + 1], prime) for i in 1:order]
end

function propose_count_recurrence(quotient; offset = 0, fit_steps = 180)
    # These primes are only a discovery device. A bad modulus or insufficient
    # reconstruction cannot produce a false positive in the exact checker.
    primes = (1_000_000_007, 1_000_000_009, 998_244_353, 1_004_535_809,
              469_762_049, 985_661_441, 943_718_401, 935_329_793)
    residues = BigInt[]
    modulus = big(1)
    for prime in primes
        values = quotient_residue_counts(quotient, fit_steps; modulus = prime, offset = offset)
        candidate = count_recurrence_mod(values, prime)
        isempty(residues) && (residues = zeros(BigInt, length(candidate)))
        length(candidate) == length(residues) || error("modular orders disagree; no recurrence certified")
        inverse = invmod(mod(modulus, prime), prime)
        for i in eachindex(residues)
            correction = mod((candidate[i] - residues[i]) * inverse, prime)
            residues[i] += modulus * correction
        end
        modulus *= prime
    end
    return [2 * value > modulus ? value - modulus : value for value in residues]
end

function quotient_residue_counts(quotient, steps; modulus = nothing, offset = 0)
    steps >= 0 || throw(ArgumentError("steps must be nonnegative"))
    offset in 0:2 || throw(ArgumentError("offset must be 0, 1, or 2"))
    counts = modulus === nothing ? copy(quotient.initial_counts) : Int.(mod.(quotient.initial_counts, modulus))
    values = eltype(counts)[]
    for n in 0:(offset + 3 * steps)
        if n >= offset && mod(n - offset, 3) == 0
            value = sum(counts[quotient.accepting])
            push!(values, modulus === nothing ? value : mod(value, modulus))
        end
        n == offset + 3 * steps && break
        following = fill(zero(eltype(counts)), length(counts))
        for edge in quotient.edges
            following[edge.to] += edge.multiplicity * counts[edge.from]
            modulus === nothing || (following[edge.to] = mod(following[edge.to], modulus))
        end
        counts = following
    end
    return values
end

"""
Certify a scalar recurrence for counts at n=19+offset+3k, starting at k=start.
If the representation has d states, d zero residuals suffice: each residual
is a fixed linear functional of (M^3)^k times a fixed vector, so Cayley-Hamilton
propagates those zeros forever. All arithmetic here is exact, without a prime.
"""
function certify_count_recurrence(quotient, coefficients; start = 0, offset = 0)
    start >= 0 || throw(ArgumentError("start must be nonnegative"))
    isempty(coefficients) && throw(ArgumentError("the recurrence must have positive order"))
    dimension, order = length(quotient.accepting), length(coefficients)
    values = quotient_residue_counts(quotient, start + order + dimension - 1; offset = offset)
    for k in start:(start + dimension - 1)
        predicted = sum(coefficients[i] * values[k + order - i + 1] for i in 1:order)
        predicted == values[k + order + 1] || return false
    end
    return true
end

function count_recurrence_integer_factors(coefficients; roots = -16:16)
    polynomial = vcat(big(1), -BigInt.(coefficients))
    factors = Pair{Int, Int}[]
    for root in roots
        multiplicity = 0
        while length(polynomial) > 1
            quotient = BigInt[polynomial[1]]
            for i in 2:(length(polynomial) - 1)
                push!(quotient, polynomial[i] + root * quotient[end])
            end
            polynomial[end] + root * quotient[end] == 0 || break
            polynomial = quotient
            multiplicity += 1
        end
        multiplicity > 0 && push!(factors, root => multiplicity)
    end
    return (integer_factors = factors, remainder = polynomial)
end

function count_polynomial_product(left, right)
    result = zeros(BigInt, length(left) + length(right) - 1)
    for i in eachindex(left), j in eachindex(right)
        result[i + j - 1] += left[i] * right[j]
    end
    return result
end

function count_polynomial_power(polynomial, exponent)
    exponent >= 0 || throw(ArgumentError("exponent must be nonnegative"))
    result = BigInt[1]
    for _ in 1:exponent
        result = count_polynomial_product(result, polynomial)
    end
    return result
end

function count_monic_polynomial_root(polynomial, exponent)
    exponent > 0 || throw(ArgumentError("exponent must be positive"))
    first(polynomial) == 1 || throw(ArgumentError("polynomial must be monic"))
    mod(length(polynomial) - 1, exponent) == 0 || error("degree is not divisible by exponent")
    degree = div(length(polynomial) - 1, exponent)
    root = BigInt[1]
    for k in 1:degree
        known = count_polynomial_power(vcat(root, big(0)), exponent)[k + 1]
        numerator = polynomial[k + 1] - known
        mod(numerator, exponent) == 0 || error("polynomial has no integer monic root")
        push!(root, div(numerator, exponent))
    end
    count_polynomial_power(root, exponent) == polynomial || error("polynomial is not a perfect power")
    return root
end
