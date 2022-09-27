include("debug.jl")

### base
Base.first(coll) = isempty(coll) ? coll : coll[1]

###  collections

is_scalar(sc) = any(x -> isa(sc, x), [Number, Symbol, String, Char])
is_coll(coll) = isa(coll, Vector) || isa(coll, Tuple)
is_dict(d) = isa(d, Dict)

remove(f, coll) = filter(x -> !f(x), coll)
# println(remove(x -> x == 5, [1,2,5,5,4,5,7]))

rest(coll) = length(coll) < 2 ? [] : coll[2:end]

pushl(coll, el) = begin
    insert!(coll, 1, el)
    coll
end

pushr(coll, el) = begin
    insert!(coll, length(coll) + 1, el)
    coll
end

split_with(f, coll, left = []) = begin
    if isempty(coll)
        (left, coll)
    elseif f(first(coll))
        split_with(f, rest(coll), pushr(left, first(coll)))
    else
        (left, coll)
    end
end
# a, b = split_with(x -> x < 7, [1,6,9,3,4,5])
# println(a)

### dictionaries (maps, hashes)
# struct GeneralDict{K, V} <: Dict where {K<:Any, V<:Any}

delete(dict::Dict{K, V}, key_to_delete::K) where {K <: Any, V <: Any} = Dict(k => v for (k, v) in dict if k != key_to_delete)

reduce_dict(f, acc_value, dict) = begin
    dict_copy = copy(dict)
    if isempty(dict_copy)
        acc_value
    else
        next_k, next_v = first(dict_copy)
        delete!(dict_copy, next_k)
        reduce_dict(f, f(acc_value, (next_k, next_v)), dict_copy)
    end
end
# n = 10000
# foo = Dict(map(=>, 1:n, [0,0,0,0,0,0,1,0,0,0]))
# foo = Dict(map(=>, 1:n, rand(n)))
# @time res = reduce_dict((acc, (k,v)) -> merge(acc, Dict(k => "a")), Dict(), foo)
# @time res = reduce_dict((acc, (k,v)) -> acc + v, Dict(), foo)
# println(res)

Base.filter(f, dict::Dict{K, V}) where {K <: Any, V <: Any}  = begin
    dict_copy = copy(dict)
    filter!(pair -> f(pair[1], pair[2]), dict_copy)
end

# n = 10
# foo = Dict(map(=>, 1:n, rand(n)))
# println(filter((k, v) -> k > 5, foo))
# @p methods(filter!)

### regexps
ismatch = occursin

re_find(re, str) = begin
    max_captures_n = 10
    m = match(re, str)
    empty_result = repeat([""], max_captures_n)
    result = typeof(m) == Nothing ?
        empty_result :
        [m.match; m.captures; empty_result][1:max_captures_n]
end

re_seq(re, str) = begin
    ms = collect(eachmatch(re, str))
    map(m -> if length(m) == 0
                String(m.match)
            elseif isempty(m.captures)
                String(m.match)
            else
                [String(m.match); map(String, remove(isnothing, m.captures))]
            end,
        ms)
end

# @p re_seq(r"([a-z]+):([^\s]+)", "factor1 foo:23 bar:54 city:Moscow")
# @p Dict(k => v for (_, k, v) in re_seq(r"([a-z]+):([^\s]+)", "factor1 foo:23 bar:54 city:Moscow"))
