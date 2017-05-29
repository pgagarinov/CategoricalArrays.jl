using Nulls

@compat const DefaultRefType = UInt32

## Pools

# V is always set to CategoricalValue{T}
# This workaround is needed since this type not defined yet
# See JuliaLang/julia#269
if VERSION >= v"0.6.0-dev.2643"
    include_string("""
        type CategoricalPool{T, R <: Integer, V}
            index::Vector{T}
            invindex::Dict{T, R}
            order::Vector{R}
            levels::Vector{T}
            valindex::Vector{V}
            ordered::Bool

            function CategoricalPool{T, R, V}(index::Vector{T},
                                              invindex::Dict{T, R},
                                              order::Vector{R},
                                              ordered::Bool) where {T, R, V}
                pool = new(index, invindex, order, index[order], V[], ordered)
                buildvalues!(pool)
                return pool
            end
        end
    """)
else
    @eval begin
        type CategoricalPool{T, R <: Integer, V}
            index::Vector{T}
            invindex::Dict{T, R}
            order::Vector{R}
            levels::Vector{T}
            valindex::Vector{V}
            ordered::Bool

            function CategoricalPool{T, R}(index::Vector{T},
                                           invindex::Dict{T, R},
                                           order::Vector{R},
                                           ordered::Bool)
                pool = new(index, invindex, order, index[order], V[], ordered)
                buildvalues!(pool)
                return pool
            end
        end
    end
end

immutable LevelsException{T, R} <: Exception
    levels::Vector{T}
end

## Values

immutable CategoricalValue{T, R <: Integer}
    level::R
    pool::CategoricalPool{T, R, CategoricalValue{T, R}}
end

## Arrays

@compat abstract type AbstractCategoricalArray{T, N, R, V} <: AbstractArray{Union{CategoricalValue{V, R}, T}, N} end
@compat AbstractCategoricalVector{T, R, V} = AbstractCategoricalArray{T, 1, R, V}
@compat AbstractCategoricalMatrix{T, R, V} = AbstractCategoricalArray{T, 2, R, V}

immutable CategoricalArray{T, N, R <: Integer, V} <: AbstractCategoricalArray{T, N, R, V}
    refs::Array{R, N}
    pool::CategoricalPool{V, R, CategoricalValue{V, R}}

    function CategoricalArray{T, N, R, V}(refs::Array{R, N},
                                          pool::CategoricalPool{V, R, CategoricalValue{V, R}}) where
                                          {T, N, R<:Integer, V}
        T === V || T === Union{T, Null} || throw(ArgumentError("T must be equal to V or to Union{V, Null}"))
        new(refs, pool)
    end
end
@compat CategoricalVector{T, R, V} = CategoricalArray{T, 1, V}
@compat CategoricalMatrix{T, R, V} = CategoricalArray{T, 2, V}

## Nullable Arrays

@compat abstract type AbstractNullableCategoricalArray{T, N, R} <: AbstractArray{Union{CategoricalValue{T, R}, Null}, N} end
@compat AbstractNullableCategoricalVector{T, R} = AbstractNullableCategoricalArray{T, 1, R}
@compat AbstractNullableCategoricalMatrix{T, R} = AbstractNullableCategoricalArray{T, 2, R}

@compat NullableCategoricalArray{T, N, R} = CategoricalArray{Union{T, Null}, N, R, T}
@compat NullableCategoricalVector{T, R} = NullableCategoricalArray{T, 1, R}
@compat NullableCategoricalMatrix{T, R} = NullableCategoricalArray{T, 2, R}

## Type Aliases

@compat CatArray{T, N, R} = Union{CategoricalArray{T, N, R}, NullableCategoricalArray{T, N, R}}
@compat CatVector{T, R} = Union{CategoricalVector{T, R}, NullableCategoricalVector{T, R}}
