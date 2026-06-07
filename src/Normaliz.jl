module Normaliz

using CxxWrap

export Cone
export computed_cone_properties, cone_property, is_computed, known_cone_properties

include("setup.jl")

get_libnormaliz_julia_path() = Setup.locate_libnormaliz_julia()
@wrapmodule(get_libnormaliz_julia_path, :define_module_normaliz)

function __init__()
    @initcxx
end

Base.convert(::Type{NmzRational},x::Rational{Int64}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzRational},x::Rational{Int32}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzInteger},x::Int64) = NmzInteger(x)
Base.convert(::Type{NmzInteger},x::BigInt) = _NmzInteger_from_bigint(x)
function Base.convert(::Type{BigInt},x::NmzInteger)
    result = BigInt()
    _set_bigint!(result,x)
    return result
end
Base.convert(::Type{NmzRational},x::Int64) = NmzRational(x,1)
Base.convert(::Type{NmzRational},x::BigInt) =
    NmzRational(convert(NmzInteger,x), NmzInteger(1))
Base.convert(::Type{NmzRational},x::NmzInteger) =
    NmzRational(x, NmzInteger(1))
Base.://(x::NmzInteger,y::NmzInteger) = NmzRational(x,y)
Base.convert(::Type{NmzRational},x::Rational{BigInt}) =
    convert(NmzInteger,x.num) // convert(NmzInteger,x.den)
Base.numerator(x::NmzRational) = _numerator(x)
Base.denominator(x::NmzRational) = _denominator(x)
Base.convert(::Type{Rational{BigInt}},x::NmzRational) =
    convert(BigInt,numerator(x)) // convert(BigInt,denominator(x))

Base.size(x::NmzMatrix) = (nrows(x),ncols(x))
#Base.size(x::NmzVector) = (length(x),)


#Base.getindex(M::NmzVector,dims...) = _getindex(M,Int64(dims[1]))
Base.getindex(M::NmzMatrix,dims...) = _getindex(M,Int64(dims[1]),Int64(dims[2]))
Base.getindex(M::NmzMatrix,I::CartesianIndex{2}) = M[I[1], I[2]]
#Base.setindex!(M::NmzVector{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]))
#Base.setindex!(M::NmzVector{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]))
Base.setindex!(M::NmzMatrix{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]),Int64(dims[2]))
Base.setindex!(M::NmzMatrix{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]),Int64(dims[2]))
#
Base.show(io::IO,x::NmzInteger) = print(io,to_string(x))
Base.show(io::IO,x::NmzRational) = print(io,to_string(x))
Base.show(io::IO,x::Cone) = print(io,"Normaliz cone")

_string_vector(x) = String.(collect(x))

"""
    known_cone_properties() -> Vector{String}

Return the names of cone properties known to Normaliz.

# Examples

```jldoctest
julia> using Normaliz

julia> "HilbertBasis" in known_cone_properties()
true
```
"""
known_cone_properties() = _string_vector(_known_cone_properties())

"""
    computed_cone_properties(cone::Cone) -> Vector{String}

Return the names of properties that have already been computed for `cone`.

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5]);

julia> "ExtremeRays" in computed_cone_properties(C)
false

julia> cone_property(C, :ExtremeRays);

julia> "ExtremeRays" in computed_cone_properties(C)
true
```
"""
computed_cone_properties(cone::Cone) = _string_vector(_computed_cone_properties(cone))

"""
    is_computed(cone::Cone, property::Union{AbstractString,Symbol}) -> Bool

Return whether `property` has already been computed for `cone`.

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5]);

julia> is_computed(C, :ExtremeRays)
false

julia> cone_property(C, :ExtremeRays);

julia> is_computed(C, :ExtremeRays)
true
```
"""
is_computed(cone::Cone, property::AbstractString) = _is_computed(cone, property)
is_computed(cone::Cone, property::Symbol) = is_computed(cone, String(property))

_julia_cone_property(x) = x
_julia_cone_property(x::NmzInteger) = convert(BigInt, x)
_julia_cone_property(x::NmzRational) = convert(Rational{BigInt}, x)
_julia_cone_property(x::NmzMatrix{NmzInteger}) = Matrix{BigInt}(x)
_julia_cone_property(x::NmzMatrix{NmzRational}) = Matrix{Rational{BigInt}}(x)
_julia_cone_property(x::CxxWrap.StdLib.StdVector{NmzInteger}) =
    convert.(BigInt, collect(x))
_julia_cone_property(x::CxxWrap.StdLib.StdVector{NmzRational}) =
    convert.(Rational{BigInt}, collect(x))

"""
    cone_property(cone::Cone, property::Union{AbstractString,Symbol})

Compute and return `property` for `cone`.

The result is converted to ordinary Julia objects where this is supported,
for example `Matrix{BigInt}`, `Vector{BigInt}`, `BigInt`,
`Rational{BigInt}`, `Float64`, `Int`, or `Bool`.

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1]);

julia> cone_property(C, :HilbertBasis)
2×2 Matrix{BigInt}:
 1  2
 3  5

julia> cone_property(C, :EmbeddingDim)
2
```
"""
function cone_property(cone::Cone, property::AbstractString)
    output_type = _cone_property_output_type(property)
    if output_type == "Matrix"
        return _julia_cone_property(get_matrix_cone_property(cone, property))
    elseif output_type == "Vector"
        return _julia_cone_property(get_vector_cone_property(cone, property))
    elseif output_type == "Integer"
        return _julia_cone_property(get_integer_cone_property(cone, property))
    elseif output_type == "GMPInteger"
        return _julia_cone_property(get_gmp_integer_cone_property(cone, property))
    elseif output_type == "Rational"
        return _julia_cone_property(get_rational_cone_property(cone, property))
    elseif output_type == "Float"
        return get_float_cone_property(cone, property)
    elseif output_type == "MachineInteger"
        return get_machine_integer_cone_property(cone, property)
    elseif output_type == "Bool"
        return get_boolean_cone_property(cone, property)
    end
    throw(ArgumentError(
        "cone property $property has unsupported output type $output_type"))
end

cone_property(cone::Cone, property::Symbol) =
    cone_property(cone, String(property))

get_matrix_cone_property(cone, property::Symbol) =
    get_matrix_cone_property(cone, String(property))
get_vector_cone_property(cone, property::Symbol) =
    get_vector_cone_property(cone, String(property))
get_integer_cone_property(cone, property::Symbol) =
    get_integer_cone_property(cone, String(property))
get_gmp_integer_cone_property(cone, property::Symbol) =
    get_gmp_integer_cone_property(cone, String(property))
get_rational_cone_property(cone, property::Symbol) =
    get_rational_cone_property(cone, String(property))
get_float_cone_property(cone, property::Symbol) =
    get_float_cone_property(cone, String(property))
get_machine_integer_cone_property(cone, property::Symbol) =
    get_machine_integer_cone_property(cone, String(property))
get_boolean_cone_property(cone, property::Symbol) =
    get_boolean_cone_property(cone, String(property))

function _normaliz_input(input::AbstractDict)
    input_pairs = collect(pairs(input))
    input_keys = String[]
    input_matrices = NmzMatrix{NmzRational}[]
    for (key, matrix) in input_pairs
        key isa Symbol ||
            throw(ArgumentError("Normaliz cone input keys must be Symbols"))
        push!(input_keys, String(key))
        push!(input_matrices, _normaliz_input_matrix(key, matrix))
    end
    input_keys = CxxWrap.StdLib.StdVector{CxxWrap.StdLib.StdString}(input_keys)
    input_matrices = CxxRef.(input_matrices)
    return input_keys, input_matrices
end

_normaliz_input_matrix(key::Symbol, matrix::NmzMatrix{NmzRational}) = matrix

function _normaliz_input_matrix(key::Symbol, matrix::AbstractMatrix)
    try
        return NmzMatrix{NmzRational}(matrix)
    catch err
        throw(ArgumentError(
            "Normaliz cone input value for :$key must be convertible " *
            "to NmzMatrix{NmzRational}"))
    end
end

function _normaliz_input_matrix(key::Symbol, value)
    throw(ArgumentError(
        "Normaliz cone input values must be matrices; " *
        "value for :$key has type $(typeof(value))"))
end

function NmzMatrix{T}(x::AbstractMatrix{S}) where S where T
   s = size(x)
   mat = NmzMatrix{T}(s[1],s[2])
   for i in 1:s[1], j in 1:s[2]
       mat[i,j] = convert(T,x[i,j])
   end
   return mat
end

#function NmzVector{T}(x::Vector{S}) where S where T
#    s = size(x)
#    vec = NmzVector{T}(s[1])
#    for i in 1:s[1]
#        vec[i] = convert(T,x[i])
#    end
#    return vec
#end

function GMPCone(input::AbstractDict)
    input_keys, input_matrices = _normaliz_input(input)
    return _GMPCone(input_keys, input_matrices)
end

function LongLongCone(input::AbstractDict)
    input_keys, input_matrices = _normaliz_input(input)
    return _LongLongCone(input_keys, input_matrices)
end

"""
    Cone(input::AbstractDict; type::Symbol = :gmp)
    Cone(; type::Symbol = :gmp, kwargs...)

Construct a Normaliz cone from Julia matrices.

Inputs use Normaliz input names as keyword arguments or as `Symbol` keys in a
dictionary, for example `:cone` and `:grading`. Matrix entries must be
convertible to rational numbers. By default, Normaliz uses arbitrary precision
integer arithmetic; pass `type = :longlong` to use 64-bit integer arithmetic.

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1])
Normaliz cone

julia> cone_property(C, :HilbertBasis)
2×2 Matrix{BigInt}:
 1  2
 3  5
```
"""
function Cone(input::AbstractDict; type::Symbol = :gmp)
    if type in (:gmp, :bigint, :NmzInteger)
        return GMPCone(input)
    elseif type in (:longlong, :long_long, :int64, :Int64)
        return LongLongCone(input)
    end
    throw(ArgumentError("unsupported Normaliz cone type: $type"))
end

function Cone(; type::Symbol = :gmp, kwargs...)
    return Cone(Dict{Symbol,Any}(kwargs); type)
end

Cone{NmzInteger}(args...) = GMPCone(args...)
Cone{BigInt}(args...)     = GMPCone(args...)
Cone{Int64}(args...)      = LongLongCone(args...)

@static if @isdefined Renf
  include("renf.jl")
end

end # module
