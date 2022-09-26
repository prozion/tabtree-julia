include("debug.jl")
include("utils.jl")

### logic
and(xs...) = begin
    if isempty(xs)
        true
    elseif all(x -> x != false, xs)
        last(xs)
    else
        false
    end
end

or(xs...) = begin
    if isempty(xs)
        false
    else
        x = first(xs)
        if x == false
            or(rest(xs)...)
        else
            x
        end
    end
end

# @p or(false, false, 3, true, 10, 20)
