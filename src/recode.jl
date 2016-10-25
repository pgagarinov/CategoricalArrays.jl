"""
    recode!(dest::AbstractArray, src::AbstractArray, pairs::Pair...; default=Nullable())

Fill `dest` with elements from `src`, replacing those matching a key of `pairs`
with the corresponding value.

For each `Pair` in `pairs`, if the element is equal to (according to `isequal`) or `in` the key
(first item of the pair), then the corresponding value (second item) is copied to `src`.
If the element matches no key and `default` is `nothing` (the default), it is copied as-is;
if `default` is set to a different value, it is used instead of the original element.
Set `default=error()` if you want to ensure all elements match at least one key.
`dest` and `src` must be of the same length, but not necessarily of the same type.
Elements of `src` as well as values from `pairs` will be `convert`ed when possible
on assignment.
If an element matches more than one key, the first match is used.
"""
function recode!(dest::AbstractArray, src::AbstractArray, pairs::Pair...; default=nothing)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    lens = [length(p.first) for p in pairs]
    @inbounds for i in eachindex(dest, src)
        for j in 1:length(pairs)
            p = pairs[j]
            if (lens[j] == 1 && isequal(src[i], p.first)) ||
               (lens[j] > 1 && src[i] in p.first)
                dest[i] = p.second
                @goto nextitem
            end
        end

        # Value not in any of the pairs
        dest[i] = ifelse(default == nothing, src[i], default)

        @label nextitem
    end

    dest
end

function recode!{T}(dest::CatArray{T}, src::AbstractArray, pairs::Pair...; default=nothing)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    levs = T[p.second for p in pairs]
    if default !== nothing
        try
            push!(levs, default)
        catch err
            isa(err, MethodError) || rethrow(err)
            throw(ArgumentError("cannot `convert` default value $(repr(default)) (of type $(typeof(default))) to type of recoded levels ($T). Choose a value compatible with type of recoded levels."))
        end
    end

    levels!(dest.pool, levs)

    lens = [length(p.first) for p in pairs]
    drefs = dest.refs
    pairmap = [findfirst(levs, l) for l in levs]
    defaultref = length(levs)
    @inbounds for i in eachindex(drefs, src)
        for j in 1:length(pairs)
            p = pairs[j]
            if (lens[j] == 1 && isequal(src[i], p.first)) ||
               (lens[j] > 1 && src[i] in p.first)
                drefs[i] = pairmap[j]
                @goto nextitem
            end
        end

        # Value not in any of the pairs
        if default === nothing
            try
                dest[i] = src[i] # Need a dictionary lookup, and potentially adding a new level
            catch err
                isa(err, MethodError) || rethrow(err)
                throw(ArgumentError("cannot `convert` value $(repr(src[i])) (of type $(typeof(src[i]))) to type of recoded levels ($T). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."))
            end
        else
            drefs[i] = defaultref
        end

        @label nextitem
    end

    # Put existing levels first, and sort them if possible
    # for consistency with CategoricalArray
    oldlevels = [l for l in levels(dest) if !(l in levs)]
    if method_exists(isless, (eltype(oldlevels), eltype(oldlevels)))
        sort!(oldlevels)
    end
    levels!(dest, union(oldlevels, levels(dest)))

    dest
end

function recode!{T}(dest::CatArray{T}, src::CatArray, pairs::Pair...; default=nothing)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    srclevels = levels(src)
    levs = T[p.second for p in pairs]
    if default === nothing
        # Remove recoded levels as they won't appear in result
        firsts = (p.first for p in pairs)
        keptlevels = similar(levs)
        try
            for l in keptlevels
                if !(l in firsts || any(f -> length(f) > 1 && l in f, firsts))
                    push!(keptlevels, l)
                end
            end
        catch err
            isa(err, MethodError) || rethrow(err)
            throw(ArgumentError("cannot `convert` value $(repr(src[i])) (of type $(typeof(src[i]))) to type of recoded levels ($T). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."))
        end
        levs, ordered = mergelevels(isordered(src), keptlevels, levs)   
    else
        try
            push!(levs, default)
        catch err
            isa(err, MethodError) || rethrow(err)
            throw(ArgumentError("cannot `convert` default value $(repr(default)) (of type $(typeof(default))) to type of recoded levels ($T). Choose a value compatible with type of recoded levels."))
        end
        ordered = isordered(src) # FIXME: test this
    end

    levels!(dest.pool, levs)
    ordered!(dest, ordered)

    lens = [length(p.first) for p in pairs]
    drefs = dest.refs
    srefs = src.refs

    origmap = indexin(index(src.pool), levs)
    indexmap = Vector{Int}(length(srclevels)+1)
    indexmap[1] = 0 # For null values
    pairmap = [findfirst(levs, l) for l in seconds]
    defaultref = length(levs)
    @inbounds for (i, l) in enumerate(index(src.pool))
        for j in 1:length(pairs)
            p = pairs[j]
            if (lens[j] == 1 && isequal(l, p.first)) ||
               (lens[j] > 1 && l in p.first)
                indexmap[i+1] = pairmap[j]
                @goto nextitem
            end
        end

        # Value not in any of the pairs
        if default === nothing
            indexmap[i+1] = origmap[i]
        else
            indexmap[i+1] = defaultref
        end

        @label nextitem
    end

    @inbounds for i in eachindex(drefs)
        drefs[i] = indexmap[srefs[i]+1]
    end

    dest
end

"""
    recode!(a::AbstractArray, pairs::Pair...; default=nothing)

Convenience function for in-place recoding, equivalent to `recode!(a, a, ...)`.

**Example:**
```julia
julia> x = collect(1:10);
julia> recode!(x, 1=>100, 2:4=>0, [5; 9:10]=>-1);
julia> x
10-element Array{Int64,1}:
 100
   0
   0
   0
  -1
   6
   7
   8
  -1
  -1
  ```
"""
recode!(a::AbstractArray, pairs::Pair...; default=nothing) =
    recode!(a, a, pairs...; default=default)


Base.@pure promote_pairtype(p::Pair, q::Pair) = promote_pairtype(typeof(p), typeof(q))
Base.@pure promote_pairtype(p::Pair, q::Pair, r::Pair, s::Pair...) =
    promote_pairtype(typeof(p), promote_pairtype(q, r, s...))
Base.@pure promote_pairtype{S, T}(::Type{T}, ::Type{S}) =
    Pair{promote_type(T.parameters[1], S.parameters[1]),
         promote_type(T.parameters[2], S.parameters[2])}
pair_valtype{K, V}(::Type{Pair{K, V}}) = V

"""
    recode(src::AbstractArray, pairs::Pair...; default=nothing)

Return a new `CategoricalArray` with elements from `a`, replacing elements matching a key
of `pairs` with the corresponding value. The type of the array is chosen using `promote`
so that it can hold all elements from `a` as well as replaced elements.

For each `Pair` in `pairs`, if the element is equal to (according to `isequal`) or `in` the key
(first item of the pair), then the corresponding value (second item) is used.
If the element matches no key and `default` is `nothing` (the default), it is copied as-is;
if `default` is set to a different value, it is used instead of the original element.
Set `default=error()` if you want to ensure all elements match at least one key.
If an element matches more than one key, the first match is used.

**Example:**
```julia
julia> y = recode(x, 1=>100, 2:4=>0, [5; 9:10]=>-1)
10-element CategoricalArrays.CategoricalArray{Int64,1,UInt32}:
 100
 0  
 0  
 0  
 -1 
 6  
 7  
 8  
 -1 
 -1 
  ```
"""
function recode(src::AbstractArray, pairs::Pair...; default=nothing)
    # T cannot take into account default nor eltype(src), since the former isn't specialized on,
    # and whether the latter matters is only known at compile time (all levels recoded or not)
    T = pair_valtype(promote_pairtype(pairs...))
    dest = CategoricalArray{T}(size(src))
    recode!(dest, src, pairs...; default=default)
end

function recode{S, N, R}(src::CatArray{S, N, R}, pairs::Pair...; default=nothing)
    # T cannot take into account default nor eltype(src), since the former isn't specialized on,
    # and whether the latter matters is only known at compile time (all levels recoded or not)
    T = pair_valtype(promote_pairtype(pairs...))
    dest = CategoricalArray{T, N, R}(size(src))
    recode!(dest, src, pairs...; default=default)
end
