module Normaliz

using CxxWrap

export Cone
export compute!, computed_cone_properties, cone_property, is_computed, known_cone_properties

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
Base.show(io::IO, x::Cone) =
    print(io, "Normaliz cone of embedding dimension ", _embedding_dim(x))

_string_vector(x) = String.(collect(x))

"""
    known_cone_properties() -> Vector{String}

Return the names of cone properties known to Normaliz, i.e. the properties that can be
computed with [`compute!`](@ref).

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
_julia_cone_property(x::NmzMatrix{Float64}) = Matrix{Float64}(x)
_julia_cone_property(x::CxxWrap.StdLib.StdVector{NmzInteger}) =
    convert.(BigInt, collect(x))
_julia_cone_property(x::CxxWrap.StdLib.StdVector{NmzRational}) =
    convert.(Rational{BigInt}, collect(x))

"""
    Normaliz.HilbertSeries

A Hilbert or Ehrhart series ``t^s h(t) / ∏ᵢ (1 - t^{dᵢ})``, as returned by
[`cone_property`](@ref) for `HilbertSeries` and `EhrhartSeries`.

# Fields

- `numerator::Vector{BigInt}`: the coefficients of ``h(t)``, starting with the
  constant term
- `denominator::Vector{Int}`: the degrees ``dᵢ``, repeated by multiplicity
- `shift::Int`: the shift ``s``

With the flag `HSOP = true`, the denominator comes from a homogeneous system of
parameters.

# Examples

The triangle with vertices ``(0,0)``, ``(2,0)``, ``(0,3)`` has Ehrhart series
``(1 + 4t + t^2) / (1 - t)^3``:

```jldoctest
julia> using Normaliz

julia> C = Cone(; polytope = [0 0; 2 0; 0 3]);

julia> cone_property(C, :HilbertSeries)
Normaliz.HilbertSeries(BigInt[1, 4, 1], [1, 1, 1], 0)
```
"""
struct HilbertSeries
    numerator::Vector{BigInt}
    denominator::Vector{Int}
    shift::Int
end

Base.:(==)(a::HilbertSeries, b::HilbertSeries) =
    a.numerator == b.numerator && a.denominator == b.denominator && a.shift == b.shift
Base.hash(a::HilbertSeries, h::UInt) =
    hash(a.numerator, hash(a.denominator, hash(a.shift, hash(HilbertSeries, h))))

"""
    Normaliz.QuasiPolynomial

A Hilbert or Ehrhart quasipolynomial, as returned by [`cone_property`](@ref) for
`HilbertQuasiPolynomial` and `EhrhartQuasiPolynomial`. It agrees with the Hilbert or
Ehrhart function for all sufficiently large arguments; `q(n)` evaluates it at `n`.

# Fields

- `coefficients::Matrix{BigInt}`: row ``k + 1`` holds the coefficients, by increasing
  degree, of the polynomial for arguments congruent to ``k`` modulo the period, which
  is the number of rows
- `denominator::BigInt`: the common denominator of all coefficients

# Examples

The ``n``-th dilation of the triangle with vertices ``(0,0)``, ``(1/2,0)``,
``(0,1/2)`` contains ``\binom{⌊n/2⌋+2}{2}`` lattice points:

```jldoctest
julia> using Normaliz

julia> C = Cone(; vertices = [0 0 1; 1 0 2; 0 1 2]);

julia> q = cone_property(C, :EhrhartQuasiPolynomial)
Normaliz.QuasiPolynomial(BigInt[8 6 1; 3 4 1], 8)

julia> q.(0:5)
6-element Vector{Rational{BigInt}}:
 1
 1
 3
 3
 6
 6
```
"""
struct QuasiPolynomial
    coefficients::Matrix{BigInt}
    denominator::BigInt
end

Base.:(==)(a::QuasiPolynomial, b::QuasiPolynomial) =
    a.coefficients == b.coefficients && a.denominator == b.denominator
Base.hash(a::QuasiPolynomial, h::UInt) =
    hash(a.coefficients, hash(a.denominator, hash(QuasiPolynomial, h)))

function (q::QuasiPolynomial)(n::Integer)
    coefficients = q.coefficients[mod(n, size(q.coefficients, 1)) + 1, :]
    return evalpoly(BigInt(n), coefficients) // q.denominator
end

function _julia_series(cone::Cone, series)
    # as in PyNormaliz, an HSOP computation determines the representation
    if is_computed(cone, "HSOP")
        return HilbertSeries(_julia_cone_property(_series_hsop_numerator(series)),
                             collect(_series_hsop_denominator(series)),
                             _series_shift(series))
    end
    return HilbertSeries(_julia_cone_property(_series_numerator(series)),
                         collect(_series_denominator(series)),
                         _series_shift(series))
end

_julia_quasipolynomial(series) =
    QuasiPolynomial(Matrix{BigInt}(_quasipolynomial(series)),
                    convert(BigInt, _quasipolynomial_denominator(series)))

# getters for the properties of output type "Complex" that `cone_property` supports;
# they read results, so the property must be computed first
const _COMPLEX_CONE_PROPERTIES = Dict{String,Function}(
    "HilbertSeries" => cone -> _julia_series(cone, _hilbert_series(cone)),
    "EhrhartSeries" => cone -> _julia_series(cone, _ehrhart_series(cone)),
    "HilbertQuasiPolynomial" => cone -> _julia_quasipolynomial(_hilbert_series(cone)),
    "EhrhartQuasiPolynomial" => cone -> _julia_quasipolynomial(_ehrhart_series(cone)),
)

function _flag_names(flags)
    names = String[]
    for (name, value) in pairs(flags)
        value isa Bool || throw(ArgumentError(
            "Normaliz flag $name must be true or false, got $(repr(value))"))
        value && push!(names, String(name))
    end
    return names
end

"""
    compute!(cone::Cone, property, properties...; flags...) -> Cone

Compute one or more properties for `cone` in a single Normaliz run, and return
`cone`. The results are not returned: retrieve them afterwards with
[`cone_property`](@ref), which does not compute them again. Normaliz throws an error
if it cannot compute one of the properties, unless the flag `DefaultMode = true` is
given, in which case it skips such properties (see [`is_computed`](@ref)).

Use `compute!` to compute several properties together, which lets Normaliz share work
between them instead of requesting them one by one. To compute and retrieve a single
property, call `cone_property` directly.

Property names are those listed by [`known_cone_properties`](@ref). `flags` select
how Normaliz computes them, given as `Bool` keyword arguments named after the Normaliz
flag, e.g. `DualMode = true` to use the dual algorithm, or `BigInt = true` to compute
with arbitrary precision integers. Flags set to `false` are ignored. Any flag known to
Normaliz is accepted; see the section "Computation goals and algorithmic variants" of
the [Normaliz manual](https://github.com/Normaliz/Normaliz/blob/master/doc/Normaliz.pdf).
Normaliz throws an error for unknown names and for contradictory flags, such as
`DualMode` together with `PrimalMode`.

Normaliz never recomputes a property, so `flags` have no effect on properties that
have already been computed (see [`is_computed`](@ref)).

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1]);

julia> compute!(C, :HilbertBasis, :Multiplicity; DualMode = true);

julia> cone_property(C, :Multiplicity)
1//24
```
"""
function compute!(cone::Cone, property::Union{AbstractString,Symbol},
                  properties::Union{AbstractString,Symbol}...; flags...)
    _compute_skipped(cone, (property, properties...), _flag_names(flags))
    return cone
end

# returns the names of goals that Normaliz skipped, which happens only with DefaultMode
function _compute_skipped(cone::Cone, properties, flag_names::Vector{String})
    names = String[String(p) for p in properties]
    append!(names, flag_names)
    return _string_vector(
        _compute(cone, CxxWrap.StdLib.StdVector{CxxWrap.StdLib.StdString}(names)))
end

# Normaliz output types that `cone_property` converts to Julia objects
const _SUPPORTED_OUTPUT_TYPES = ("Matrix", "MatrixFloat", "Vector", "Integer", "GMPInteger",
                                  "Rational", "Float", "MachineInteger", "Bool")

"""
    cone_property(cone::Cone, property::Union{AbstractString,Symbol}; flags...)

Return `property` of `cone`, computing it first if it has not been computed yet.

Property names are those listed by [`known_cone_properties`](@ref). The result is
converted to an ordinary Julia object: `Matrix{BigInt}`, `Matrix{Float64}`,
`Vector{BigInt}`, `BigInt`, `Rational{BigInt}`, `Float64`, `Int`, or `Bool`, depending
on the property. The series `HilbertSeries` and `EhrhartSeries` are returned as
[`Normaliz.HilbertSeries`](@ref), and `HilbertQuasiPolynomial` and
`EhrhartQuasiPolynomial` as [`Normaliz.QuasiPolynomial`](@ref). Properties with other
kinds of results, such as `Triangulation`, are not yet supported and throw an
`ArgumentError`.

`flags` are `Bool` keyword arguments, e.g. `DualMode = true`, exactly as for
[`compute!`](@ref).

# Examples

```jldoctest
julia> using Normaliz

julia> C = Cone(; cone = [1 2; 3 5], grading = [1 1]);

julia> cone_property(C, :HilbertBasis; DualMode = true)
2×2 Matrix{BigInt}:
 1  2
 3  5

julia> cone_property(C, :EmbeddingDim)
2
```
"""
function cone_property(cone::Cone, property::AbstractString; flags...)
    output_type = String(_cone_property_output_type(property))
    complex_getter = get(_COMPLEX_CONE_PROPERTIES, property, nothing)
    output_type in _SUPPORTED_OUTPUT_TYPES || complex_getter !== nothing ||
        throw(ArgumentError(
            "cone property $property has unsupported output type $output_type"))
    flag_names = _flag_names(flags)
    if !isempty(flag_names)
        # with DefaultMode, Normaliz may skip the property; the getter below would then
        # compute it without the flags
        property in _compute_skipped(cone, (property,), flag_names) && error(
            "Normaliz could not compute $property with flags $(join(flag_names, ", "))")
    elseif complex_getter !== nothing
        compute!(cone, property)
    end
    complex_getter === nothing || return complex_getter(cone)
    if output_type == "Matrix"
        return _julia_cone_property(get_matrix_cone_property(cone, property))
    elseif output_type == "MatrixFloat"
        return _julia_cone_property(get_float_matrix_cone_property(cone, property))
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
    else # output_type == "Bool"
        return get_boolean_cone_property(cone, property)
    end
end

cone_property(cone::Cone, property::Symbol; flags...) =
    cone_property(cone, String(property); flags...)

get_matrix_cone_property(cone, property::Symbol) =
    get_matrix_cone_property(cone, String(property))
get_float_matrix_cone_property(cone, property::Symbol) =
    get_float_matrix_cone_property(cone, String(property))
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
Normaliz cone of embedding dimension 2

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
