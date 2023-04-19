module Normaliz

import Base: convert

import Nemo: fmpq_poly

import Libdl

using CxxWrap

const libnormaliz_julia_path = joinpath(@__DIR__, "..", "deps", "src", "build", "libnormaliz_julia.$(Libdl.dlext)")
@wrapmodule(libnormaliz_julia_path, :define_module_normaliz)


function __init__()
    @initcxx
end

Base.convert(::Type{NmzRational},x::Rational{Int64}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzRational},x::Rational{Int32}) = NmzRational(x.num,x.den)
Base.convert(::Type{NmzInteger},x::Int64) = NmzInteger(x)
Base.convert(::Type{NmzRational},x::Int64) = NmzRational(x,1)

Base.size(x::NmzMatrix) = (nrows(x),ncols(x))
#Base.size(x::NmzVector) = (length(x),)


#Base.getindex(M::NmzVector,dims...) = _getindex(M,Int64(dims[1]))
Base.getindex(M::NmzMatrix,dims...) = _getindex(M,Int64(dims[1]),Int64(dims[2]))
#Base.setindex!(M::NmzVector{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]))
#Base.setindex!(M::NmzVector{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]))
Base.setindex!(M::NmzMatrix{T},x::T,dims...) where T = _setindex!(M,x,Int64(dims[1]),Int64(dims[2]))
Base.setindex!(M::NmzMatrix{T},x::Int64,dims...) where T = _setindex!(M,convert(T,x),Int64(dims[1]),Int64(dims[2]))
#
Base.show(io::IO,x::NmzInteger) = print(io,to_string(x))
Base.show(io::IO,x::NmzRational) = print(io,to_string(x))
Base.show(io::IO,x::Cone) = print(io,"Normaliz cone")
Base.show(io::IO,x::Renf) = print(io,to_string(x))
Base.show(io::IO,x::RenfClass) = print(io,to_string(x))

function NmzMatrix{T}(x::Matrix{S}) where S where T
   s = size(x)
   mat = NmzMatrix{T}(s[1],s[2])
   for i in 1:s[1], j in 1:s[2]
       mat[i,j] = convert(T,x[i,j])
   end
   return mat
end


function NmzMatrix{Renf}(f::RenfClass,x::Matrix{S}) where S
   s = size(x)
   mat = NmzMatrix{Renf}(s[1],s[2])
   for i in 1:s[1], j in 1:s[2]
       mat[i,j] = Renf(f,x[i,j])
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

#function Renf(f::RenfClass,v::NmzVector{NmzRational})
#   # TODO: make this work (again) without NmzVector
#   return renf_construct(f,v)
#end

#function Renf(f::RenfClass,v::Int64)
#   # TODO: make this work (again) without NmzVector
#   return renf_construct(f, NmzVector{NmzRational}([v]))
#end

function Renf(f::RenfClass,p::fmpq_poly)
   # TODO: make this work (again)
   return renf_construct_fmpq_poly(f,reinterpret(Ptr{Cvoid},pointer_from_objref(p)))
end

function RenfClass(minpoly::String, gen::String, emb::String, prec::Int = 64)
  # TODO: make this work
  return renf_class_construct(minpoly, gen, emb, prec)
end

Cone{NmzInteger}(args...) = IntCone(args...)
Cone{Int64}(args...)      = LongCone(args...)
Cone{Renf}(args...)       = RenfCone(args...)


end # module
