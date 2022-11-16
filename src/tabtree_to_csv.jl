include("odysseus/io.jl")
include("odysseus/utils.jl")
include("odysseus/debug.jl")
include("parse_tabtree.jl")
include("parse_tabtree_utils.jl")

using Pipe
using OrderedCollections

function make_value(v, delimeter)
    if isempty(v)
        v
    elseif is_coll(v)
        join(map(x-> make_value(x, delimeter), v), delimeter)
    elseif v isa Number
        v
    elseif v isa Symbol
        replace("$v", "\"", "")
    else
        v
    end
end

function make_csv(tabtree; delimeter = "\t", headers::Vector{T} = [], collection_delimeter = ",") where T <: Any
    make_csv(tabtree, delimeter = delimeter, headers = Dict(k => k for k in headers), collection_delimeter = collection_delimeter)
end

function make_csv(tabtree; delimeter="\t", headers = OrderedDict(), collection_delimeter = ",", filter_f = truef)
    items = collect(values(tabtree))
    items = filter(filter_f, items)
    all_keys = @pipe items |>
                     map(item -> [keys(item)...], _) |>
                     flatten(_) |>
                     unique(_)
    # header_keys, header_names = keys(headers), values(headers)
    used_keys = isempty(headers) ? all_keys : filter(x -> x in all_keys, collect(keys(headers)))
    header_str = join([get(headers, used_key, used_key) for used_key in used_keys], delimeter)
    make_csv_line(keys, item) = join(
                                    map(
                                        x -> make_value(
                                                get(item, x, ""),
                                                collection_delimeter),
                                        keys),
                                    delimeter)
    result = header_str
    result = reduce(
                (acc, item) -> is_empty_item(item) ? acc : "$acc" * "$(make_csv_line(used_keys, item))\n",
                items,
                init = "$result\n")
    result
end
