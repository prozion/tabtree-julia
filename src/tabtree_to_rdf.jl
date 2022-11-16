include("odysseus/io.jl")
include("odysseus/utils.jl")
include("odysseus/debug.jl")
include("parse_tabtree.jl")
include("parse_tabtree_utils.jl")

using Pipe

Namespaces = Dict()

aliases = Dict("a" => "rdf:type",
               "subclass-of" => "rdfs:subClassOf",
               "subproperty-of" => "rdfs:subPropertyOf"
               "alt" => "owl:sameAs"
               "eq" => "owl:sameAs"
               "eq-class" => "owl:equivalentClass"
               "eq-property" => "owl:equivalentProperty"
               "domain" => "rdfs:domain"
               "range" => "rdfs:range"
               "rem" => "rdfs:comment"
               "d" => "rdfs:comment"
               "deabbr" => "rdfs:label"
               "name" => "rdfs:label"
               )

default_ns = "https://example.org/ontology"

function tabtree_to_rdf(tabtree)
    tabtree = extract_imports(tabtree)
    namespaces = get_subtree(tabtree, "namespaces")
    delete!(namespaces, "namespaces")
    default_prefix = @pipe tabtree |>
                           values |>
                           filter(item -> get(item, "a", "") == "owl/Ontology", _) |>
                           isempty(_) ? default_ns : get(_, "ns", default_ns)
    header = ["@prefix : <$default_prefix> ."]
    header = [header; ["""@prefix $(haskey(v, "no-prefix") ? "" : k): <$(v["ns"])>""" for (k, v) in namespaces)]]
    tabtree
end
