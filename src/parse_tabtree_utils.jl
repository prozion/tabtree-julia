include("odysseus/utils.jl")

namespaced_key(k) = begin
    global Namespace
    isempty(Namespace) ? k : "$current_namespace/$k"
end

function count_tabs(line; count = 0)
    line_chars = split(line, "")
    if first(line) == '\t'
        count_tabs(rest(line), count = count + 1)
    else
        count
    end
end

collect_pars(re, line, f = identity) = Dict(namespaced_key(k) => f(v) for (_, k, v) in re_seq(re, line))

exists(id) = !isempty(id)

is_anon_node_id(id::String) = !isempty(re_seq(r"(?<=\b)_[1-9]?(?=\b)", id))
is_anon_node_id(id) = false

function rename_anon_node(parent_id, child_id)
    (exists(parent_id) && is_anon_node_id(child_id)) ?
        namespaced_key("$parent_id$child_id") :
        child_id
end

is_inherity(key, value) = typeof(key) == String && ismatch(r"\+[\-a-z0-9|]+", key)

get_inherities(item) = filter(is_inherity, item)

function item_plus(item, new_parameters)
    merge(item, new_parameters)
end

function item_minus(item, keys_to_remove)
    item_keys = collect(keys(item))
    if isempty(item_keys)
        item
    else
        Dict(k => item[k] for k in setdiff(item_keys, keys_to_remove))
    end
end

function deplus(s)
    deplused_name = lstrip(s, '+')
    isempty(Namespace) ?
        deplused_name :
        "$Namespace/$deplused_name"
end

incorporate_inherities(inherities) = Dict(deplus(k) => v for (k, v) in inherities)

is_rdf_list(v) = isa(v, Dict) && haskey(v, :__rdf_list)

function merge_item_vals(v1, v2)
    if all(rdf_list, [v1, v2])
        merge(v1, Dict(:__values => [v1[:__values]; v2[:__values]]))
    elseif is_dict(v1) && isa(v2, Dict)
        merge(v1, v2)
    elseif (is_dict(v1) && is_scalar(v2)) || (is_scalar(v1) && is_dict(v2))
        unique([v1; v2])
    elseif is_coll(v1) && is_coll(v2)
        unique([v1; v2])
    elseif is_scalar(v1) && is_coll(v2)
        unique(pushr(v2, v1))
    elseif is_coll(v1) && is_scalar(v2)
        unique(pushr(v1, v2))
    elseif is_scalar(v1) && is_scalar(v2)
        [v1, v2]
    else
        v2
    end
end

is_tabtree(tabtree) = all(x -> isa(x, Dict), values(tabtree))

function get_subtree(tabtree, path)
    function add_children_ids(next_children, checked_children = [])
        if isempty(next_children)
            checked_children
        else
            next_child = first(next_children)
            checked_children = [checked_children; next_child]
            new_children = get(
                            get(tabtree, next_child, Dict()),
                            :__children,
                            [])
            new_next_children = unique([rest(next_children); setdiff(new_children, checked_children)])
            add_children_ids(new_next_children, checked_children)
        end
    end
    if is_tabtree(tabtree)
        next_children = isempty(path) ? [] : path[end:end]
        children_ids = add_children_ids(next_children)
    else
        Dict()
    end
end
