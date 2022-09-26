include("odysseus/utils.jl")

namespaced_key(k) = begin
    global Namespace
    isempty(Namespace) ? k : "$current_namespace/$k"
end

function count_tabs(line; count = 0)
    line_chars = split(line, "")
    if first(line) == "\t"
        count_tabs(rest(line), count = count + 1)
    else
        count
    end
end

# (defn collect-pars
#   ([re line]
#     (collect-pars re line identity))
#   ([re line f]
#     (reduce
#       (fn [acc chunk]
#         (let [[_ key value] chunk]
#           (assoc acc (->keyword-ns key) (f value))))
#       {}
#       (re-seq re line))))

collect_pars(re, line, f = identity) = Dict(namespaced_key(k) => f(v) for (_, k, v) in re_seq(re, line))

exists(id) = !isempty(id)

is_anon_node_id(id) = !isempty(re_seq(r"(?<=\b)_[1-9]?(?=\b)", id))

function rename_anon_node(parent_id, child_id)
    (exists(parent_id) && is_anon_node_id(child_id)) ?
        namespaced_key("$parent_id$child_id") :
        child_id
end

is_inherity(key, value) = typeof(key) == String && ismatch(r"\+[\-a-z0-9|]+", key)

get_inherities(item) = filter(is_inherity, item)

function item_minus(item, keys_to_remove)
    item_keys = collect(keys(item))
    if isempty(item_keys)
        item
    else
        Dict(k => item[k] for k in setdiff(item_keys, keys_to_remove))
    end
end
