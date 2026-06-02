module Normaliz

import Libdl
import normaliz_jll

using CxxWrap

get_libnormaliz_julia_path() = joinpath(@__DIR__, "..", "deps", "src", "build", "lib", "libnormaliz_julia.$(Libdl.dlext)")
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
    for (key, _) in input_pairs
        key isa Symbol ||
            throw(ArgumentError("Normaliz cone input keys must be Symbols"))
        push!(input_keys, String(key))
    end
    input_keys = CxxWrap.StdLib.StdVector{CxxWrap.StdLib.StdString}(input_keys)
    input_matrices = CxxRef.([matrix for (_, matrix) in input_pairs])
    return input_keys, input_matrices
end

function NmzMatrix{T}(x::Matrix{S}) where S where T
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

Cone{NmzInteger}(args...) = GMPCone(args...)
Cone{BigInt}(args...)     = GMPCone(args...)
Cone{Int64}(args...)      = LongLongCone(args...)

@static if @isdefined Renf
  include("renf.jl")
end

end # module
