module Normaliz

import Base: convert

import Nemo: fmpq_poly

using CxxWrap

@static if Sys.isapple()
    @wrapmodule(joinpath(@__DIR__, "..", "deps", "src", "libnormaliz.dylib"),
        :define_module_normaliz)
elseif Sys.islinux()
    @wrapmodule(joinpath(@__DIR__, "..", "deps", "src", "libnormaliz.so"),
        :define_module_normaliz)
else
    error("System is not supported!")
end

function __init__()
    @initcxx
end

Base.convert(::Type{NmzRational},x::Rational{Int64}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzRational},x::Rational{Int32}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzInteger},x::Int64) = NmzInteger(x)
Base.convert(::Type{NmzRational},x::Int64) = NmzRational(x,1)

Base.size(x::NmzMatrix) = (rows(x),cols(x))
Base.size(x::NmzVector) = (length(x),)


Base.getindex(M::NmzVector,dims...) = _getindex(M,Int64(dims[1]))
Base.getindex(M::NmzMatrix,dims...) = _getindex(M,Int64(dims[1]),Int64(dims[2]))
Base.setindex!(M::NmzVector{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]))
Base.setindex!(M::NmzVector{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]))
Base.setindex!(M::NmzMatrix{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]),Int64(dims[2]))
Base.setindex!(M::NmzMatrix{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]),Int64(dims[2]))

Base.show(io::IO,x::NmzInteger) = print(io,to_string(x))
Base.show(io::IO,x::NmzRational) = print(io,to_string(x))
Base.show(io::IO,x::Cone) = print(io,"Normaliz cone")
Base.show(io::IO,x::Renf) = print(io,to_string(x))
Base.show(io::IO,x::RenfClass) = print(io,to_string(x))

function NmzMatrix{T}(x::Array{S,2}) where S where T
    s = size(x)
    mat = NmzMatrix{T}(s[1],s[2])
    for i in 1:s[1], j in 1:s[2]
        mat[i,j] = convert(T,x[i,j])
    end
    return mat
end

function NmzMatrix{Renf}(f::RenfClass,x::Array{S,2}) where S
    s = size(x)
    mat = NmzMatrix{Renf}(s[1],s[2])
    for i in 1:s[1], j in 1:s[2]
        mat[i,j] = Renf(f,x[i,j])
    end
    return mat
end

function NmzVector{T}(x::Array{S,1}) where S where T
    s = size(x)
    vec = NmzVector{T}(s[1])
    for i in 1:s[1]
        vec[i] = convert(T,x[i])
    end
    return vec
end

function Renf(f::RenfClass,v::NmzVector{NmzRational})
    return renf_construct(f,v)
end

function Renf(f::RenfClass,v::Int64)
    return renf_construct(f, NmzVector{NmzRational}([v]))
end

function Renf(f::RenfClass,p::fmpq_poly)
    return renf_construct_fmpq_poly(f,reinterpret(Ptr{Cvoid},pointer_from_objref(p)))
end

Cone{NmzInteger}(args...) = IntCone(args...)
Cone{Int64}(args...)      = LongCone(args...)
Cone{Renf}(args...)       = RenfCone(args...)


end # module
