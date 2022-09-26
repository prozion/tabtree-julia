include("odysseus/io.jl")
include("odysseus/utils.jl")
include("odysseus/debug.jl")
include("parse_tabtree_utils.jl")

using Pipe

Namespace = ""
Parent_id = ""

function get_item(line)
    _, id = re_find(r"^\t*([\"λ#*A-Za-zА-ЯЁа-яёα-ω0-9&@:.\-_+/|<>\\?!]+)", line)
    line = replace(line, r"\^\S+" => "")
    id = namespaced_key(id)
    id = rename_anon_node(Parent_id, id)
    value_pattern(re_value) = begin
        re_key = "[_a-zA-ZА-ЯЁа-яёα-ω0-9/\\-|+]+"
        Regex("(?<=\\s)($re_key):($re_value(?=(\\s|\$|^)))")
    end
    all_parameters = collect_pars(value_pattern("(\\S+)"), line)
    ref_parameters = collect_pars(value_pattern("[a-zA-ZА-ЯЁа-яёα-ω0-9_\\-/]+"), line)
    rdf_list_parameters = collect_pars(
                            value_pattern("[`][^`]*?[`]"),
                            line,
                            x -> Dict(
                                :__rdf_list => true,
                                :__values => @pipe x |>
                                    replace(_, "[`]" => "") |>
                                    split(_, ",") |>
                                    map(namespaced_key, _)))
    string_parameters1 = collect_pars(value_pattern("[\"][^\"]*?[\"]"), line, x -> replace(x, r"[\"]", ""))
    string_parameters2 = collect_pars(value_pattern("['][^']*?[']"), line, x -> replace(x, r"[']", ""))
    string_parameters = merge(string_parameters1, string_parameters2)
    integer_parameters = collect_pars(value_pattern("[-+0-9][0-9]{0,8}"), line, x -> parse(Int, x))
    date_parameters = collect_pars(value_pattern("[0-9x][0-9x]\\.[01x][0-9x]\\.[0-9x]{3,4}"), line)
    url_parameters = collect_pars(value_pattern("http.*?(?=[\\s])"), line)
    year_parameters = collect_pars(value_pattern("([<>])?[1-9]{1,2}(h[12]|q[1234]|xx|[0-9]x)"), line)
    multiple_parameters = collect_pars(value_pattern("[^\"`]\\S*,[\\S,]+"), line, x -> map(namespaced_key, split(x, ",")))
    multiple_ref_parameters = collect_pars(value_pattern("[^\"`][a-zA-ZА-ЯЁа-яёα-ω0-9_\\-/]*,[a-zA-ZА-ЯЁа-яёα-ω0-9_,-/]+"), line, x -> map(namespaced_key, split(x, ",")))
    multiple_integer_parameters = collect_pars(value_pattern("[-+0-9]{1,9},[-+0-9,]+"), line, x -> map(y -> parse(Int, y), split(x, ",")))
    multiple_url_parameters = collect_pars(value_pattern("http[^, ]+,.+(?=[\\s])"), line, x -> split(x, ","))
    multiple_string_parameters = collect_pars(value_pattern("[\"`][^\"`]*?[\"`],.+?[\"`]"), line, x -> map(chunk -> replace(chunk, r"(\")|`|(\\)", ""), split(x, r"(?>[\"`]),")))
    parameters = merge(
                    all_parameters,
                    rdf_list_parameters,
                    string_parameters,
                    ref_parameters,
                    url_parameters,
                    year_parameters,
                    date_parameters,
                    integer_parameters,
                    multiple_parameters,
                    multiple_ref_parameters,
                    multiple_integer_parameters,
                    multiple_string_parameters,
                    multiple_url_parameters)
    isempty(id) ?
        parameters :
        merge(parameters, Dict(:__id => namespaced_key(id)))
end

function fill_tree_iter(source_lines; global_inherities = Dict(), result = Dict())
    root_line = isempty(source_lines) ? "" : first(source_lines)
    next_lines = rest(source_lines)
    root_tabs_count = count_tabs(root_line)
    root_item = get_item(root_line)
    root_id = get(root_item, :__id, "")
    root_item = is_anon_node_id(root_id) ?
                    item_plus(root_item, Dict(:__anon => true)) :
                    root_item
    old_root_item = get(result, root_id, Dict())
    local_inherities = get_inherities(root_item)
    all_inherities = merge(global_inherities, local_inherities)
    root_item = item_minus(root_item, keys(local_inherities))
    sublines, next_block_lines = split_with(
                                    line -> count_tabs(line) > root_tabs_count,
                                    next_lines)
    top_sublines = filter(line -> count_tabs(line) == root_tabs_count + 1, sublines)
    children_ids = map(subline -> keyword_to_ns(id(get_item(subline))), top_sublines)
    root_item = isempty(children_ids) ? root_item : item_plus(root_item, children_ids[:__children])
    root_item = item_plus(incorporate_inherities(global_inherities), root_item)
    root_item = Dict(k =>
                        if is_rdf_list(v)
                            merge(v, Dict(:__values => map(node -> rename_anon_node(root_id, node), v[:__values])))
                        elseif is_coll(v)
                            map(node -> rename_anon_node(root_id, node),
                                v)
                        else
                            rename_anon_node(root_id, v)
                        end for (k, v) in root_item)
    root_item = merge(
                    mergewith(merge_item_vals, old_root_item, root_item),
                    Dict(:__id => root_id))
    result = isempty(sublines) ?
                mergewith(merge, result, Dict(root_id => root_item)) :
                global Parent_id = root_id
                mergewith(
                    merge,
                    result,
                    Dict(root_id => root_item),
                    fill_tree_iter(sublines, global_inherities = all_inherities))
    isempty(next_block_lines) ?
        result :
        fill_tree_iter(next_block_lines, global_inherities = all_inherities, result = result)
end

function parse_tabtree(treefile; namespace="")
    global Namespace = namespace
    tree_lines = readlines(treefile)
    tree_lines = remove(line -> begin
                                    ismatch(r"^\t*;.*", line) ||
                                    ismatch(r"^\s*$", line)
                                end,
                        tree_lines)
    tabtree = fill_tree_iter(tree_lines)
    # println(tree_lines)
end

# run(`pwd`)

parse_tabtree("../data/fixtures/countries.tree")
