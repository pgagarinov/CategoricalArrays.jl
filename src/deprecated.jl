@deprecate ordered isordered

@deprecate compact compress
@deprecate uncompact decompress

@deprecate CategoricalArray(::Type{T}, dims::NTuple{N,Int}; ordered=false) where {T, N} CategoricalArray{T}(dims, ordered=ordered)
@deprecate CategoricalArray(::Type{T}, dims::Int...; ordered=false) where {T} CategoricalArray{T}(dims, ordered=ordered)

@deprecate CategoricalVector(::Type{T}, m::Integer; ordered=false) where {T} CategoricalVector{T}(m, ordered=ordered)

@deprecate CategoricalMatrix(::Type{T}, m::Int, n::Int; ordered=false) where {T} CategoricalMatrix{T}(m, n, ordered=ordered)

@deprecate CategoricalArray(dims::Int...; ordered=false) CategoricalArray(undef, dims...; ordered=ordered)

@deprecate CategoricalArray{T, N, R}(dims::NTuple{N,Int}; ordered=false) where {T, N, R} CategoricalArray{T, N, R}(undef, dims; ordered=ordered)

@deprecate CategoricalArray{T, N}(dims::NTuple{N,Int}; ordered=false) where {T, N} CategoricalArray{T, N}(undef, dims; ordered=ordered)
@deprecate CategoricalArray{T}(dims::NTuple{N,Int}; ordered=false) where {T, N} CategoricalArray{T}(undef, dims; ordered=ordered)
@deprecate CategoricalArray{T, 1}(m::Int; ordered=false) where {T} CategoricalArray{T, 1}(undef, m; ordered=ordered)
@deprecate CategoricalArray{T, 2}(m::Int, n::Int; ordered=false) where {T} CategoricalArray{T, 2}(undef, m, n; ordered=ordered)
@deprecate CategoricalArray{T, 1, R}(m::Int; ordered=false) where {T, R} CategoricalArray{T, 1, R}(undef, m; ordered=ordered)
# R <: Integer is required to prevent default constructor from being called instead
@deprecate CategoricalArray{T, 2, R}(m::Int, n::Int; ordered=false) where {T, R <: Integer} CategoricalArray{T, 2, R}(undef, m, n; ordered=ordered)
@deprecate CategoricalArray{T, 3, R}(m::Int, n::Int, o::Int; ordered=false) where {T, R} CategoricalArray{T, 3, R}(undef, m, n, o; ordered=ordered)
@deprecate CategoricalArray{T}(m::Int; ordered=false) where {T} CategoricalArray{T}(undef, m; ordered=ordered)
@deprecate CategoricalArray{T}(m::Int, n::Int; ordered=false) where {T} CategoricalArray{T}(undef, m, n; ordered=ordered)
@deprecate CategoricalArray{T}(m::Int, n::Int, o::Int; ordered=false) where {T} CategoricalArray{T}(undef, m, n, o; ordered=ordered)

@deprecate CategoricalVector(m::Integer; ordered=false) CategoricalVector(undef, m; ordered=ordered)
@deprecate CategoricalVector{T}(m::Int; ordered=false) where {T} CategoricalVector{T}(undef, m; ordered=ordered)

@deprecate CategoricalMatrix(m::Int, n::Int; ordered=false) CategoricalMatrix(undef, m, n; ordered=ordered)
@deprecate CategoricalMatrix{T}(m::Int, n::Int; ordered=false) where {T} CategoricalMatrix{T}(undef, m::Int, n::Int; ordered=ordered)

Base.@deprecate_binding CategoricalString CategoricalValue{String}
Base.@deprecate_binding CatValue Union{CategoricalValue, CategoricalValue{String}}

@deprecate iscatvalue(x::Type) x <: CategoricalValue && x !== Union{}
@deprecate iscatvalue(x::Any) typeof(x) <: CategoricalValue

@deprecate(catvaluetype(::Type{T}, ::Type{R}) where {T >: Missing, R},
    CategoricalValue{CategoricalArrays.leveltype(Base.nonmissingtype(T)), R})
@deprecate(catvaluetype(::Type{<:CategoricalValue{T}}, ::Type{R}) where {T >: Missing, R},
    CategoricalValue{CategoricalArrays.leveltype(Base.nonmissingtype(T)), R})

# AbstractString interface for CategoricalString
import Base: eltype, length, lastindex, sizeof, nextind, prevind,
    iterate, getindex, codeunit, ascii, isvalid, match, collect, reverse,
    ncodeunits, isempty, firstindex, lpad, rpad, occursin, startswith, endswith,
    repeat, split, rsplit, strip, lstrip, rstrip, eachmatch,
    uppercase, lowercase, titlecase, uppercasefirst, lowercasefirst,
    chop, chomp, escape_string, textwidth, isascii
# NOTE: drop dependency on Unicode when removing these deprecations
import Unicode: normalize, graphemes
@deprecate eltype(x::CategoricalValue{String}) eltype(String(x))
@deprecate length(x::CategoricalValue{String}) length(String(x))
@deprecate lastindex(x::CategoricalValue{String}) lastindex(String(x))
@deprecate sizeof(x::CategoricalValue{String}) sizeof(String(x))
@deprecate nextind(x::CategoricalValue{String}, i::Int) nextind(String(x), i)
@deprecate prevind(x::CategoricalValue{String}, i::Int) prevind(String(x), i)
@deprecate iterate(x::CategoricalValue{String}) iterate(String(x))
@deprecate iterate(x::CategoricalValue{String}, i::Int) iterate(String(x), i)
@deprecate getindex(x::CategoricalValue{String}, i::Int) getindex(String(x), i)
@deprecate codeunit(x::CategoricalValue{String}, i::Integer) codeunit(String(x), i)
@deprecate ascii(x::CategoricalValue{String}) ascii(String(x))
@deprecate isvalid(x::CategoricalValue{String}) isvalid(String(x))
@deprecate isvalid(x::CategoricalValue{String}, i::Integer) isvalid(String(x), i)
@deprecate match(r::Regex, s::CategoricalValue{String},
      idx::Integer=firstindex(s), add_opts::UInt32=UInt32(0); kwargs...) match(r, String(s), idx, add_opts; kwargs...)
@deprecate collect(x::CategoricalValue{String}) collect(String(x))
@deprecate reverse(x::CategoricalValue{String}) reverse(String(x))
@deprecate ncodeunits(x::CategoricalValue{String}) ncodeunits(String(x))

# Methods which are not strictly necessary
# but which allow giving a single and accurate deprecation warning
@deprecate isempty(x::CategoricalValue{String}) isempty(String(x))
@deprecate firstindex(x::CategoricalValue{String}) firstindex(String(x))
@deprecate normalize(x::CategoricalValue{String}, s::Symbol) normalize(String(x), s)
@deprecate graphemes(x::CategoricalValue{String}) graphemes(String(x))
@deprecate length(x::CategoricalValue{String}, i::Int, j::Int) length(String(x), i, j)
@deprecate repeat(x::CategoricalValue{String}, i::Integer) repeat(String(x), i)
@deprecate eachmatch(r::Regex, x::CategoricalValue{String}; overlap=false) eachmatch(r, String(x), overlap=overlap)
@deprecate lpad(x::CategoricalValue{String}, n::Integer, c::Union{AbstractChar,AbstractString}=' ') lpad(String(x), n)
@deprecate rpad(x::CategoricalValue{String}, n::Integer, c::Union{AbstractChar,AbstractString}=' ') rpad(String(x), n)
@deprecate occursin(x::CategoricalValue{String}, y::AbstractString) occursin(String(x), y)
@deprecate occursin(x::AbstractString, y::CategoricalValue{String}) occursin(x, String(y))
@deprecate occursin(x::Regex, y::CategoricalValue{String}) occursin(x, String(y))
@deprecate occursin(x::AbstractChar, y::CategoricalValue{String}) occursin(x, String(y))
@deprecate startswith(x::CategoricalValue{String}, y::AbstractString) startswith(String(x), y)
@deprecate startswith(x::AbstractString, y::CategoricalValue{String}) startswith(x, String(y))
@deprecate endswith(x::CategoricalValue{String}, y::AbstractString) endswith(String(x), y)
@deprecate endswith(x::AbstractString, y::CategoricalValue{String}) endswith(x, String(y))
@deprecate split(x::CategoricalValue{String}; kwargs...) split(String(x); kwargs...)
@deprecate rsplit(x::CategoricalValue{String}; kwargs...) rsplit(String(x); kwargs...)
@deprecate strip(x::CategoricalValue{String}) strip(String(x))
@deprecate lstrip(x::CategoricalValue{String}) lstrip(String(x))
@deprecate rstrip(x::CategoricalValue{String}) rstrip(String(x))
@deprecate lowercase(x::CategoricalValue{String}) lowercase(String(x))
@deprecate uppercase(x::CategoricalValue{String}) uppercase(String(x))
@deprecate lowercasefirst(x::CategoricalValue{String}) lowercasefirst(String(x))
@deprecate uppercasefirst(x::CategoricalValue{String}) uppercasefirst(String(x))
@deprecate titlecase(x::CategoricalValue{String}) titlecase(String(x))
@deprecate chop(x::CategoricalValue{String}; kwargs...) chop(String(x); kwargs...)
@deprecate chomp(x::CategoricalValue{String}) chomp(String(x))
@deprecate textwidth(x::CategoricalValue{String}) textwidth(String(x))
@deprecate isascii(x::CategoricalValue{String}) isascii(String(x))
@deprecate escape_string(x::CategoricalValue{String}) escape_string(String(x))

# Avoid printing a deprecation until CategoricalValue{String} is no longer AbstractString
Base.write(io::IO, x::CategoricalValue{String}) = write(io, get(x))
Base.escape_string(io::IO, x::CategoricalValue{String}, esc) = escape_string(io, get(x), esc)
Base.tostr_sizehint(x::CategoricalValue{String}) = Base.tostr_sizehint(get(x))