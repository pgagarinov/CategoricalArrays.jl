"""
    recode!(dest::AbstractArray, src::AbstractArray, pairs::Pair...)
    recode!(dest::AbstractArray, src::AbstractArray, default::Any, pairs::Pair...)

Fill `dest` with elements from `src`, replacing those matching a key of `pairs`
with the corresponding value.

For each `Pair` in `pairs`, if the element is equal to (according to `isequal`) or `in` the key
(first item of the pair), then the corresponding value (second item) is copied to `src`.
If the element matches no key and `default` is not provided or `nothing`, it is copied as-is;
if `default` is specified, it is used in place of the original element.
`dest` and `src` must be of the same length, but not necessarily of the same type.
Elements of `src` as well as values from `pairs` will be `convert`ed when possible
on assignment.
If an element matches more than one key, the first match is used.
"""
function recode! end

recode!(dest::AbstractArray, src::AbstractArray, pairs::Pair...) =
    recode!(dest, src, nothing, pairs...)

function recode!(dest::AbstractArray, src::AbstractArray, default::Any, pairs::Pair...)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    @inbounds for i in eachindex(dest, src)
        for j in 1:length(pairs)
            p = pairs[j]
            if (!isa(p.first, Union{AbstractArray, Tuple}) && isequal(src[i], p.first)) ||
               (isa(p.first, Union{AbstractArray, Tuple}) && src[i] in p.first)
                dest[i] = p.second
                @goto nextitem
            end
        end

        # Value not in any of the pairs
        dest[i] = default == nothing ? src[i] : default

        @label nextitem
    end

    dest
end

function recode!{T}(dest::CatArray{T}, src::AbstractArray, default::Any, pairs::Pair...)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    levs = T[p.second for p in pairs]
    if default !== nothing
        push!(levs, default)
    end

    levels!(dest.pool, levs)

    drefs = dest.refs
    defaultref = length(levs)
    @inbounds for i in eachindex(drefs, src)
        for j in 1:length(pairs)
            p = pairs[j]
            if (!isa(p.first, Union{AbstractArray, Tuple}) && isequal(src[i], p.first)) ||
               (isa(p.first, Union{AbstractArray, Tuple}) && src[i] in p.first)
                drefs[i] = j
                @goto nextitem
            end
        end

        # Value not in any of the pairs
        if default === nothing
            v = src[i]
            try
                dest[i] = v # Need a dictionary lookup, and potentially adding a new level
            catch err
                isa(err, MethodError) || rethrow(err)
                throw(ArgumentError("cannot `convert` value $(repr(v)) (of type $(typeof(v))) to type of recoded levels ($T). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."))
            end
        else
            drefs[i] = defaultref
        end

        @label nextitem
    end

    # Put existing levels first, and sort them if possible
    # for consistency with CategoricalArray
    oldlevels = setdiff(levels(dest), levs)
    if method_exists(isless, (eltype(oldlevels), eltype(oldlevels)))
        sort!(oldlevels)
    end
    levels!(dest, union(oldlevels, levels(dest)))

    dest
end

function recode!{T}(dest::CatArray{T}, src::CatArray, default::Any, pairs::Pair...)
    if length(dest) != length(src)
        error("dest and src must be of the same length (got $(length(dest)) and $(length(src)))")
    end

    srclevels = levels(src)
    seconds = T[p.second for p in pairs]
    if default === nothing
        # Remove recoded levels as they won't appear in result
        firsts = (p.first for p in pairs)
        keptlevels = Vector{T}()
        sizehint!(keptlevels, length(srclevels))

        for l in srclevels
            if !(l in firsts || any(f -> length(f) > 1 && l in f, firsts))
                try
                    push!(keptlevels, l)
                catch err
                    isa(err, MethodError) || rethrow(err)
                    throw(ArgumentError("cannot `convert` value $(repr(l)) (of type $(typeof(l))) to type of recoded levels ($T). This will happen when not all original levels are recoded (i.e. some are preserved) and their type is incompatible with that of recoded levels."))
                end
            end
        end
        levs, ordered = mergelevels(isordered(src), keptlevels, seconds)
        pairmap = indexin(seconds, levs)
    else
        levs = push!(seconds, default)
        ordered = isordered(src) # FIXME: test this
    end

    levels!(dest.pool, levs)
    ordered!(dest, ordered)

    drefs = dest.refs
    srefs = src.refs

    origmap = indexin(index(src.pool), levs)
    indexmap = Vector{Int}(length(srclevels)+1)
    indexmap[1] = 0 # For null values
    defaultref = length(levs)
    @inbounds for (i, l) in enumerate(index(src.pool))
        for j in 1:length(pairs)
            p = pairs[j]
            if (!isa(p.first, Union{AbstractArray, Tuple}) && isequal(l, p.first)) ||
               (isa(p.first, Union{AbstractArray, Tuple}) && l in p.first)
                indexmap[i+1] = default === nothing ? pairmap[j] : j
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
    recode!(a::AbstractArray, pairs::Pair...)
    recode!(a::AbstractArray, default::Any, pairs::Pair...)

Convenience function for in-place recoding, equivalent to `recode!(a, a, ...)`.

**Example:**
```julia
julia> x = collect(1:10)
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
recode!(a::AbstractArray, default::Any, pairs::Pair...) = recode!(a, a, default, pairs...)
recode!(a::AbstractArray, pairs::Pair...) = recode!(a, a, nothing, pairs...)

promote_valuetype() = Union{}
promote_valuetype{K, V}(x::Pair{K, V}) = V
promote_valuetype{K, V}(x::Pair{K, V}, y::Pair...) = promote_type(V, promote_valuetype(y...))

"""
    recode(a::AbstractArray, pairs::Pair...)
    recode(a::AbstractArray, default::Any, pairs::Pair...)

Return a new `CategoricalArray` with elements from `a`, replacing elements matching a key
of `pairs` with the corresponding value. The type of the array is chosen so that it can
hold all recoded elements (but not necessarily original elements from `a`).

For each `Pair` in `pairs`, if the element is equal to (according to `isequal`) or `in` the key
(first item of the pair), then the corresponding value (second item) is copied to `src`.
If the element matches no key and `default` is not provided or `nothing`, it is copied as-is;
if `default` is specified, it is used in place of the original element.
If an element matches more than one key, the first match is used.

**Example:**
```julia
julia> recode(1:10, 1=>100, 2:4=>0, [5; 9:10]=>-1)
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
function recode end

recode(a::AbstractArray, pairs::Pair...) = recode(a, nothing, pairs...)

function recode(a::AbstractArray, default::Any, pairs::Pair...)
    V = promote_valuetype(pairs...)
    # T cannot take into account eltype(src), since we can't know
    # whether it matters at compile time (all levels recoded or not)
    # and using a wider type than necessary would be annoying
    T = default === nothing ? V : promote_type(typeof(default), V)
    dest = CategoricalArray{T}(size(a))
    recode!(dest, a, default, pairs...)
end

# FIXME: should not be needed, but @inferred is confused without it
recode(a::CatArray, pairs::Pair...) = recode(a, nothing, pairs...)

function recode{S, N, R}(a::CatArray{S, N, R}, default::Any, pairs::Pair...)
    V = promote_valuetype(pairs...)
    # T cannot take into account eltype(src), since we can't know
    # whether it matters at compile time (all levels recoded or not)
    # and using a wider type than necessary would be annoying
    T = default === nothing ? V : promote_type(typeof(default), V)
    dest = CategoricalArray{T, N, R}(size(a))
    recode!(dest, a, default, pairs...)
end
